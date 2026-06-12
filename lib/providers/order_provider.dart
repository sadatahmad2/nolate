import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/mock_data.dart';

class OrderProvider extends ChangeNotifier {
  OrderModel? _activeOrder;
  final List<OrderModel> _orderHistory = [];

  OrderModel? get activeOrder => _activeOrder;
  List<OrderModel> get orderHistory => [..._orderHistory];

  Timer? _movementTimer;
  double _deliveryProgress = 0.0; // 0.0 (at shop) to 1.0 (at customer)
  double get deliveryProgress => _deliveryProgress;

  OrderModel placeOrder({
    required Shop shop,
    required List<CartItem> items,
    required double totalAmount,
    required double deliveryFee,
    required double tax,
    required AppUser user,
  }) {
    // Stop any existing simulation
    _movementTimer?.cancel();
    _deliveryProgress = 0.0;

    // Pick a random rider from mockRiders
    final riderIndex = Random().nextInt(mockRiders.length);
    final selectedRider = mockRiders[riderIndex];

    // Reset rider position to shop location
    selectedRider.currentPosition = shop.location;

    final newOrder = OrderModel(
      id: '#${10000 + Random().nextInt(90000)}',
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

    // Start auto transition simulation (optional, but let's provide methods to trigger manually via simulator panel)
    return newOrder;
  }

  void updateOrderStatus(OrderStatus status) {
    if (_activeOrder == null) return;

    _activeOrder!.status = status;
    
    // Position handling based on status
    if (status == OrderStatus.placed ||
        status == OrderStatus.accepted ||
        status == OrderStatus.preparing) {
      _deliveryProgress = 0.0;
      _activeOrder!.rider.currentPosition = _activeOrder!.shop.location;
      _activeOrder!.currentRiderPosition = _activeOrder!.shop.location;
      _movementTimer?.cancel();
    } else if (status == OrderStatus.outForDelivery) {
      // Start moving rider towards customer
      _startRiderMovement();
    } else if (status == OrderStatus.delivered) {
      _deliveryProgress = 1.0;
      _activeOrder!.rider.currentPosition = _activeOrder!.customerLocation;
      _activeOrder!.currentRiderPosition = _activeOrder!.customerLocation;
      _movementTimer?.cancel();
    }

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
  }

  void _startRiderMovement() {
    _movementTimer?.cancel();
    const duration = Duration(milliseconds: 200);
    
    _movementTimer = Timer.periodic(duration, (timer) {
      if (_activeOrder == null || _activeOrder!.status != OrderStatus.outForDelivery) {
        timer.cancel();
        return;
      }

      if (_deliveryProgress < 1.0) {
        _deliveryProgress += 0.02; // Take ~10 seconds to deliver
        if (_deliveryProgress >= 1.0) {
          _deliveryProgress = 1.0;
          _activeOrder!.status = OrderStatus.delivered;
          timer.cancel();
        }

        final newPos = Coordinate.lerp(
          _activeOrder!.shop.location,
          _activeOrder!.customerLocation,
          _deliveryProgress,
        );

        _activeOrder!.rider.currentPosition = newPos;
        _activeOrder!.currentRiderPosition = newPos;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void clearActiveOrder() {
    _activeOrder = null;
    _deliveryProgress = 0.0;
    _movementTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }
}
