import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class WishlistProvider extends ChangeNotifier {
  final Map<String, WishlistItem> _items = {};

  WishlistProvider() {
    _loadWishlist();
  }

  List<WishlistItem> get items => _items.values.toList()..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  int get itemCount => _items.length;

  bool isWishlisted(String productId) {
    return _items.containsKey(productId);
  }

  void toggleWishlist(MenuItem item, Shop shop) {
    if (_items.containsKey(item.id)) {
      _items.remove(item.id);
    } else {
      _items[item.id] = WishlistItem(
        item: item,
        shop: shop,
        addedAt: DateTime.now(),
      );
    }
    _saveWishlist();
    notifyListeners();
  }

  void clearWishlist() {
    _items.clear();
    _saveWishlist();
    notifyListeners();
  }

  Future<void> _saveWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> itemsJson = {};
    _items.forEach((key, value) {
      itemsJson[key] = value.toJson();
    });
    await prefs.setString('wishlist_items', json.encode(itemsJson));
  }

  Future<void> _loadWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? itemsString = prefs.getString('wishlist_items');
      if (itemsString != null) {
        final Map<String, dynamic> itemsJson = json.decode(itemsString);
        itemsJson.forEach((key, value) {
          _items[key] = WishlistItem.fromJson(value);
        });
      }
      notifyListeners();
    } catch (e) {
      print('Error loading wishlist: $e');
    }
  }
}
