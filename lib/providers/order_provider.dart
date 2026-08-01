import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../models/mock_data.dart';
import '../services/shared_storage.dart';

class OrderProvider extends ChangeNotifier {
  OrderModel? _activeOrder;
  List<OrderModel> _orderHistory = [];

  OrderModel? get activeOrder => _activeOrder;
  List<OrderModel> get orderHistory => [..._orderHistory];

  Timer? _movementTimer;
  Timer? _syncTimer;
  double _deliveryProgress = 0.0; // 0.0 (at shop) to 1.0 (at customer)
  double get deliveryProgress => _deliveryProgress;

  OrderProvider() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        fetchOrderHistory();
      } else {
        _orderHistory = [];
        _activeOrder = null;
        notifyListeners();
      }
    });
    fetchOrderHistory();
  }

  Future<void> fetchOrderHistory() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      List<OrderModel> orders = [];
      if (user != null) {
        orders = await SharedStorageService.loadCustomerOrders(user.id);
      }
      
      // Inject dummy order if empty for demonstration
      if (orders.isEmpty && mockShops.isNotEmpty) {
        final dummyOrder = OrderModel(
          id: 'mock_order_12345',
          shop: mockShops[0],
          items: [
            CartItem(item: mockShops[0].menu[0], quantity: 2),
            CartItem(item: mockShops[0].menu[1], quantity: 1),
          ],
          totalAmount: 160.0,
          deliveryFee: 30.0,
          tax: 8.0,
          status: OrderStatus.delivered,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          rider: mockRiders[0],
          customerLocation: const Coordinate(28.0, 77.0),
          currentRiderPosition: const Coordinate(28.0, 77.0),
        );
        orders.add(dummyOrder);
      }

      _orderHistory = orders;
      
      // Optionally set the active order if there's one that is not delivered/cancelled
      try {
        final active = orders.firstWhere((o) => o.status != OrderStatus.delivered);
        _activeOrder = active;
        _startSyncingActiveOrder();
      } catch (_) {}

      notifyListeners();
    } catch (e) {
      print("fetchOrderHistory error: $e");
    }
  }

  Future<OrderModel> placeOrder({
    required Shop shop,
    required List<CartItem> items,
    required double totalAmount,
    required double deliveryFee,
    required double tax,
    required AppUser user,
  }) async {
    // Stop any existing simulation and sync
    _movementTimer?.cancel();
    _syncTimer?.cancel();
    _deliveryProgress = 0.0;

    // Pick a random rider from mockRiders
    final riderIndex = Random().nextInt(mockRiders.length);
    final selectedRider = mockRiders[riderIndex];

    // Reset rider position to shop location
    selectedRider.currentPosition = shop.location;

    // Push to Supabase
    final supabase = Supabase.instance.client;
    String orderIdStr;
    try {
      final orderRes = await supabase.from('orders').insert({
        'customer_id': supabase.auth.currentUser!.id,
        'shop_id': shop.id,
        'total_amount': totalAmount + deliveryFee + tax,
        'delivery_fee': deliveryFee,
        'tax': tax,
        'status': 'pending',
        'payment_status': 'paid',
        'customer_location': {
          'address': user.address,
          'lat': user.location.x,
          'lng': user.location.y,
        }
      }).select().single();

      orderIdStr = orderRes['id'];

      final orderItemsData = items.map((cartItem) {
        return {
          'order_id': orderIdStr,
          'product_id': cartItem.item.id,
          'quantity': cartItem.quantity,
          'price': cartItem.item.price,
        };
      }).toList();

      await supabase.from('order_items').insert(orderItemsData);
    } catch (e) {
      print("Error inserting order: $e");
      orderIdStr = '#${10000 + Random().nextInt(90000)}'; // fallback if error
    }

    final newOrder = OrderModel(
      id: orderIdStr,
      shop: shop,
      items: items,
      totalAmount: totalAmount,
      deliveryFee: deliveryFee,
      tax: tax,
      status: OrderStatus.placed,
      rider: selectedRider,
      timestamp: DateTime.now(),
      customerLocation: user.location,
      currentRiderPosition: shop.location,
    );

    _activeOrder = newOrder;
    _orderHistory.insert(0, newOrder);
    notifyListeners();

    // Write the order to the shared database so the merchant app detects it (legacy fallback)
    SharedStorageService.saveOrder(newOrder);

    // Start background polling to check if the merchant updates the status
    _startSyncingActiveOrder();

    return newOrder;
  }

  void updateOrderStatus(OrderStatus status) {
    if (_activeOrder == null) return;
    _activeOrder!.status = status;
    
    // NOTE: Removed SharedStorageService.updateOrderStatus because the customer app 
    // should only READ the status from the backend, not overwrite it during sync.
    notifyListeners();
    
    // Position handling based on status
    if (status == OrderStatus.placed ||
        status == OrderStatus.accepted ||
        status == OrderStatus.preparing) {
      _deliveryProgress = 0.0;
      _activeOrder!.rider.currentPosition = _activeOrder!.shop.location;
      _activeOrder!.currentRiderPosition = _activeOrder!.shop.location;
      _movementTimer?.cancel();
    } else if (status == OrderStatus.delivered) {
      _deliveryProgress = 1.0;
      _activeOrder!.rider.currentPosition = _activeOrder!.customerLocation;
      _activeOrder!.currentRiderPosition = _activeOrder!.customerLocation;
      _movementTimer?.cancel();
    }
    // NOTE: Removed SharedStorageService.saveOrder to prevent overwriting DB during sync
    notifyListeners();
  }

  void setManualProgress(double progress) {
    if (_activeOrder == null) return;
    
    _movementTimer?.cancel(); // Cancel auto-movement if user slides manually
    _deliveryProgress = progress.clamp(0.0, 1.0);
    
    final newPos = Coordinate.lerp(
      _activeOrder!.shop.location,
      _activeOrder!.customerLocation,
      _deliveryProgress,
    );
    
    _activeOrder!.rider.currentPosition = newPos;
    _activeOrder!.currentRiderPosition = newPos;

    if (_deliveryProgress >= 1.0 && _activeOrder!.status != OrderStatus.delivered) {
      _activeOrder!.status = OrderStatus.delivered;
    } else if (_deliveryProgress > 0.0 && _deliveryProgress < 1.0 && _activeOrder!.status != OrderStatus.outForDelivery) {
      _activeOrder!.status = OrderStatus.outForDelivery;
    }

    notifyListeners();
    SharedStorageService.saveOrder(_activeOrder!);
  }

  /// Polls Supabase to check for status updates from the merchant.
  void _startSyncingActiveOrder() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_activeOrder == null) {
        timer.cancel();
        return;
      }
      try {
        final supabase = Supabase.instance.client;
        final res = await supabase
            .from('orders')
            .select('status, customer_location')
            .eq('id', _activeOrder!.id)
            .maybeSingle();

        if (res != null) {
          final String statusStr = res['status'] as String;
          OrderStatus newStatus = _activeOrder!.status;
          
          switch (statusStr) {
            case 'pending':
            case 'placed':
              newStatus = OrderStatus.placed;
              break;
            case 'accepted':
              newStatus = OrderStatus.accepted;
              break;
            case 'preparing':
              newStatus = OrderStatus.preparing;
              break;
            case 'ready':
              newStatus = OrderStatus.preparing; // ready = merchant prepared
              break;
            case 'out_for_delivery':
            case 'outForDelivery':
              newStatus = OrderStatus.outForDelivery;
              break;
            case 'delivered':
              newStatus = OrderStatus.delivered;
              break;
            case 'cancelled':
              newStatus = OrderStatus.delivered; // fallback
              break;
          }
          
          final custLoc = res['customer_location'] as Map<String, dynamic>?;
          bool attributesUpdated = false;
          if (custLoc != null) {
              if (custLoc.containsKey('rider_lat') && custLoc.containsKey('rider_lng')) {
                 final double lat = (custLoc['rider_lat'] as num).toDouble();
                 final double lng = (custLoc['rider_lng'] as num).toDouble();
                 final newPos = Coordinate(lat, lng);
                 _activeOrder!.currentRiderPosition = newPos;
                 _activeOrder!.rider.currentPosition = newPos;
                 attributesUpdated = true;
              }

              if (custLoc.containsKey('rider_name')) {
                 final realRiderName = custLoc['rider_name'] as String;
                 if (_activeOrder!.rider.name != realRiderName) {
                     _activeOrder!.rider = Rider(
                         name: realRiderName,
                         phone: custLoc['rider_phone'] ?? _activeOrder!.rider.phone,
                         vehicle: _activeOrder!.rider.vehicle,
                         vehicleNumber: _activeOrder!.rider.vehicleNumber,
                         rating: _activeOrder!.rider.rating,
                         currentPosition: _activeOrder!.rider.currentPosition,
                     );
                     attributesUpdated = true;
                 }
              }
          }
          
          if (newStatus != _activeOrder!.status || attributesUpdated) {
            if (newStatus != _activeOrder!.status) {
                updateOrderStatus(newStatus);
            } else {
                notifyListeners(); // just rider updated
            }
          }
        }
      } catch (e) {
        print("Sync error: $e");
      }
    });
  }

  void clearActiveOrder() {
    _activeOrder = null;
    _deliveryProgress = 0.0;
    _movementTimer?.cancel();
    _syncTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
