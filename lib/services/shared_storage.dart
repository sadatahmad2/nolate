import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SharedStorageService {
  static final _supabase = Supabase.instance.client;

  // ─── SHOPS ───

  /// Loads custom merchant-created shops.
  static Future<List<Shop>> loadShops() async {
    try {
      final response = await _supabase
          .from('shops')
          .select('*, products(*)');
      
      final List<Shop> shops = [];
      for (var s in response) {
        final productsList = s['products'] as List? ?? [];
        final List<MenuItem> menu = productsList.map((p) => MenuItem(
          id: p['id'].toString(),
          name: p['name'] ?? '',
          description: p['description'] ?? '',
          price: (p['price'] as num?)?.toDouble() ?? 0.0,
          category: p['category'] ?? 'Grocery',
          imageUrl: p['image_url'] ?? '',
        )).toList();

        shops.add(Shop(
          id: s['id'].toString(),
          name: s['shop_name'] ?? '',
          category: s['category'] ?? 'Grocery',
          rating: (s['rating'] as num?)?.toDouble() ?? 5.0,
          deliveryTimeMinutes: s['delivery_time_minutes'] ?? 15,
          distanceKm: 1.0,
          imageUrl: s['logo_url'] ?? 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80',
          location: Coordinate(
            (s['latitude'] as num?)?.toDouble() ?? 0.5,
            (s['longitude'] as num?)?.toDouble() ?? 0.5,
          ),
          menu: menu,
        ));
      }
      return shops;
    } catch (e) {
      print('loadShops error: $e');
      return [];
    }
  }

  /// Registers a new merchant shop in Supabase.
  static Future<void> saveShop(Shop shop) async {
    try {
      final user = _supabase.auth.currentUser;
      final ownerId = user?.id ?? '00000000-0000-0000-0000-000000000000';
      await _supabase.from('shops').insert({
        'id': shop.id.contains('-') ? shop.id : null,
        'owner_id': ownerId,
        'shop_name': shop.name,
        'category': shop.category,
        'latitude': shop.location.x,
        'longitude': shop.location.y,
        'rating': shop.rating,
        'delivery_time_minutes': shop.deliveryTimeMinutes,
        'logo_url': shop.imageUrl,
        'status': 'open',
      });
    } catch (e) {
      print('saveShop error: $e');
    }
  }

  /// Adds a new product item to a specific merchant shop.
  static Future<void> addMenuItem(String shopId, MenuItem item) async {
    try {
      await _supabase.from('products').insert({
        'shop_id': shopId,
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'category': item.category,
        'image_url': item.imageUrl,
        'status': 'available',
      });
    } catch (e) {
      print('addMenuItem error: $e');
    }
  }

  // ─── ORDERS ───

  static Future<List<OrderModel>> loadOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, order_items(*), shops(*)');

      final productsResponse = await _supabase.from('products').select('*');
      final Map<String, dynamic> productMap = {
        for (var p in productsResponse) p['id'].toString(): p
      };

      return _parseOrders(response, productMap);
    } catch (e) {
      print('loadOrders error: $e');
      return [];
    }
  }

  /// Loads all orders for a specific customer from Supabase.
  static Future<List<OrderModel>> loadCustomerOrders(String customerId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, order_items(*), shops(*)')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      final productsResponse = await _supabase.from('products').select('*');
      final Map<String, dynamic> productMap = {
        for (var p in productsResponse) p['id'].toString(): p
      };

      return _parseOrders(response, productMap);
    } catch (e) {
      print('loadCustomerOrders error: $e');
      return [];
    }
  }

  static List<OrderModel> _parseOrders(dynamic response, Map<String, dynamic> productMap) {
      final List<OrderModel> orders = [];
      for (var o in response) {
        final shopData = o['shops'];
        if (shopData == null) continue;

        final shop = Shop(
          id: shopData['id'].toString(),
          name: shopData['shop_name'] ?? '',
          category: shopData['category'] ?? '',
          rating: (shopData['rating'] as num?)?.toDouble() ?? 5.0,
          deliveryTimeMinutes: shopData['delivery_time_minutes'] ?? 15,
          distanceKm: 1.0,
          imageUrl: shopData['logo_url'] ?? '',
          location: Coordinate(
            (shopData['latitude'] as num?)?.toDouble() ?? 0.5,
            (shopData['longitude'] as num?)?.toDouble() ?? 0.5,
          ),
          menu: [],
        );

        final itemsList = o['order_items'] as List? ?? [];
        final List<CartItem> items = itemsList.map((oi) {
          final p = productMap[oi['product_id']?.toString()];
          return CartItem(
            item: MenuItem(
              id: p != null ? p['id'].toString() : '',
              name: p != null ? p['name'] ?? '' : '',
              description: p != null ? p['description'] ?? '' : '',
              price: (oi['price'] as num?)?.toDouble() ?? (p != null ? (p['price'] as num?)?.toDouble() : 0.0) ?? 0.0,
              category: p != null ? p['category'] ?? '' : '',
              imageUrl: p != null ? p['image_url'] ?? '' : '',
            ),
            quantity: oi['quantity'] ?? 1,
          );
        }).toList();

        final custLoc = o['customer_location'] as Map? ?? {'x': 0.5, 'y': 0.5};
        final statusStr = o['status'] ?? 'pending';
        
        OrderStatus status = OrderStatus.placed;
        if (statusStr == 'accepted') status = OrderStatus.accepted;
        else if (statusStr == 'preparing') status = OrderStatus.preparing;
        else if (statusStr == 'out_for_delivery' || statusStr == 'outForDelivery') status = OrderStatus.outForDelivery;
        else if (statusStr == 'delivered') status = OrderStatus.delivered;
        // 'pending' and 'placed' both map to OrderStatus.placed

        orders.add(OrderModel(
          id: o['id'].toString(),
          shop: shop,
          items: items,
          totalAmount: (o['total_amount'] as num?)?.toDouble() ?? 0.0,
          deliveryFee: (o['delivery_fee'] as num?)?.toDouble() ?? 0.0,
          tax: (o['tax'] as num?)?.toDouble() ?? 0.0,
          status: status,
          rider: Rider(
            name: 'Nolate Rider',
            phone: '9999999999',
            vehicle: 'Electric Scooter',
            vehicleNumber: 'DL 3C AB 1234',
            rating: 4.8,
            currentPosition: shop.location,
          ),
          timestamp: DateTime.tryParse(o['created_at'] ?? '') ?? DateTime.now(),
          customerLocation: Coordinate(
            (custLoc['x'] as num?)?.toDouble() ?? 0.5,
            (custLoc['y'] as num?)?.toDouble() ?? 0.5,
          ),
          currentRiderPosition: shop.location,
        ));
      }
      return orders;
  }

  /// Saves or updates an order in Supabase.
  static Future<void> saveOrder(OrderModel order) async {
    try {
      final user = _supabase.auth.currentUser;
      final customerId = user?.id ?? '00000000-0000-0000-0000-000000000000';

      final statusStr = order.status == OrderStatus.placed ? 'pending' :
                        order.status == OrderStatus.accepted ? 'accepted' :
                        order.status == OrderStatus.preparing ? 'preparing' :
                        order.status == OrderStatus.outForDelivery ? 'out_for_delivery' : 'delivered';

      // 1. Insert/Upsert the order
      final orderResponse = await _supabase.from('orders').upsert({
        'id': order.id.contains('-') ? order.id : null,
        'customer_id': customerId,
        'shop_id': order.shop.id,
        'total_amount': order.totalAmount,
        'delivery_fee': order.deliveryFee,
        'tax': order.tax,
        'status': statusStr,
        'payment_status': 'paid',
        'customer_location': {
          'x': order.customerLocation.x,
          'y': order.customerLocation.y,
        },
      }).select();

      if (orderResponse.isNotEmpty) {
        final newOrderId = orderResponse[0]['id'];

        // 2. Insert items (only if it's a new order insertion)
        if (!order.id.contains('-')) {
          final List<Map<String, dynamic>> itemsToInsert = order.items.map((ci) => {
            'order_id': newOrderId,
            'product_id': ci.item.id,
            'quantity': ci.quantity,
            'price': ci.item.price,
          }).toList();
          
          await _supabase.from('order_items').insert(itemsToInsert);
        }
      }
    } catch (e) {
      print('saveOrder error: $e');
    }
  }

  /// Updates status of a specific order.
  static Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final statusStr = status == OrderStatus.placed ? 'pending' :
                        status == OrderStatus.accepted ? 'accepted' :
                        status == OrderStatus.preparing ? 'preparing' :
                        status == OrderStatus.outForDelivery ? 'out_for_delivery' : 'delivered';

      await _supabase.from('orders').update({
        'status': statusStr,
      }).eq('id', orderId);
    } catch (e) {
      print('updateOrderStatus error: $e');
    }
  }
}
