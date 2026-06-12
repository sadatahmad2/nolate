import 'package:flutter/material.dart';
import '../models/models.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  Shop? _currentShop;

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
    // Base delivery fee of 30 plus 15 per km
    return 30.0 + (_currentShop!.distanceKm * 15.0).roundToDouble();
  }

  double get tax {
    if (_items.isEmpty) return 0.0;
    // 5% GST
    return (totalAmount * 0.05).roundToDouble();
  }

  double get grandTotal => totalAmount + deliveryFee + tax;

  // Returns true if addition was successful, false if we need confirmation to switch shops
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
  }

  void removeItem(String itemId) {
    _items.remove(itemId);
    if (_items.isEmpty) {
      _currentShop = null;
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _currentShop = null;
    notifyListeners();
  }
}
