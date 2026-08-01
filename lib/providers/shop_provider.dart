import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class ShopProvider extends ChangeNotifier {
  List<Shop> _shops = [];
  bool _isLoading = false;
  String? _error;

  List<Shop> get shops => List.unmodifiable(_shops);
  bool get isLoading => _isLoading;
  String? get error => _error;

  ShopProvider() {
    fetchShopsFromSupabase();
  }

  /// Fetch all shops from Supabase
  Future<void> fetchShopsFromSupabase() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('shops')
          .select('id, shop_name, category, owner_id, image_url')
          .order('created_at', ascending: false);

      final List<Shop> fetchedShops = [];

      for (final row in response) {
        // Fetch products for this shop
        final productsRes = await Supabase.instance.client
            .from('products')
            .select('*')
            .eq('shop_id', row['id']);

        final List<MenuItem> menuItems = (productsRes as List).map((p) {
          return MenuItem.fromJson(p);
        }).toList();

        fetchedShops.add(Shop(
          id: row['id'].toString(),
          name: row['shop_name'] ?? 'Shop',
          category: row['category'] ?? 'General',
          rating: 4.5,
          deliveryTimeMinutes: 20,
          distanceKm: 1.0,
          imageUrl: row['image_url'] ?? '',
          menu: menuItems,
          location: const Coordinate(0.5, 0.5),
        ));
      }

      _shops = fetchedShops;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchShopsFromSupabase();
}
