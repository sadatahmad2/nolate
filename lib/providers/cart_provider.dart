import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  Shop? _currentShop;

  CartProvider() {
    _loadCart();
  }

  Map<String, CartItem> get items => {..._items};
  Shop? get currentShop => _currentShop;

  int get itemCount => _items.length;

  List<CartItem> get itemsList => _items.values.toList();

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.total;
    });
    return total;
  }

  double get deliveryFee {
    if (_items.isEmpty || _currentShop == null) return 0.0;
    return 30.0 + (_currentShop!.distanceKm * 15.0).roundToDouble();
  }

  double get actualDeliveryFee {
    return totalAmount >= 200 ? 0.0 : deliveryFee;
  }

  double get platformFee {
    if (_items.isEmpty) return 0.0;
    return 7.0;
  }

  double get grandTotal {
    return totalAmount + actualDeliveryFee + platformFee;
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save items
    final Map<String, dynamic> itemsJson = {};
    _items.forEach((key, value) {
      itemsJson[key] = value.toJson();
    });
    await prefs.setString('cart_items', json.encode(itemsJson));

    // Save shop
    if (_currentShop != null) {
      await prefs.setString('cart_shop', json.encode(_currentShop!.toJson()));
    } else {
      await prefs.remove('cart_shop');
    }
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final String? shopString = prefs.getString('cart_shop');
      if (shopString != null) {
        _currentShop = Shop.fromJson(json.decode(shopString));
        // If the shop is from old mock data (doesn't have UUID), clear the cart
        if (!_currentShop!.id.contains('-')) {
          clearCart();
          return;
        }
      }

      final String? itemsString = prefs.getString('cart_items');
      if (itemsString != null) {
        final Map<String, dynamic> itemsJson = json.decode(itemsString);
        itemsJson.forEach((key, value) {
          _items[key] = CartItem.fromJson(value);
        });
      }
      notifyListeners();
    } catch (e) {
      // In case of parsing error, log it
      print('Error loading cart: $e');
    }
  }

  bool addItem(MenuItem item, Shop shop) {
    if (_currentShop != null && _currentShop!.id != shop.id) {
      return false; // Prompt user to clear cart from previous shop
    }

    _currentShop = shop;

    if (_items.containsKey(item.id)) {
      _items.update(
        item.id,
        (existing) => CartItem(item: existing.item, quantity: existing.quantity + 1),
      );
    } else {
      _items.putIfAbsent(
        item.id,
        () => CartItem(item: item, quantity: 1),
      );
    }

    notifyListeners();
    _saveCart();
    return true;
  }

  void forceAddItem(MenuItem item, Shop shop) {
    _items.clear();
    _currentShop = shop;
    _items.putIfAbsent(
      item.id,
      () => CartItem(item: item, quantity: 1),
    );
    notifyListeners();
    _saveCart();
  }

  void removeSingleItem(String itemId) {
    if (!_items.containsKey(itemId)) return;

    if (_items[itemId]!.quantity > 1) {
      _items.update(
        itemId,
        (existing) => CartItem(item: existing.item, quantity: existing.quantity - 1),
      );
    } else {
      _items.remove(itemId);
    }

    if (_items.isEmpty) {
      _currentShop = null;
    }

    notifyListeners();
    _saveCart();
  }

  void removeItem(String itemId) {
    _items.remove(itemId);
    if (_items.isEmpty) {
      _currentShop = null;
    }
    notifyListeners();
    _saveCart();
  }

  void clearCart() {
    _items.clear();
    _currentShop = null;
    notifyListeners();
    _saveCart();
  }
}
