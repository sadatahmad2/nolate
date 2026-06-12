import 'dart:math';

class Coordinate {
  final double x; // From 0.0 to 1.0 (relative canvas width)
  final double y; // From 0.0 to 1.0 (relative canvas height)

  const Coordinate(this.x, this.y);

  double distanceTo(Coordinate other) {
    return sqrt(pow(x - other.x, 2) + pow(y - other.y, 2));
  }

  static Coordinate lerp(Coordinate a, Coordinate b, double t) {
    return Coordinate(
      a.x + (b.x - a.x) * t,
      a.y + (b.y - a.y) * t,
    );
  }
}

class AppUser {
  final String name;
  final String mobile;
  final String email;
  final String password;
  final String address;
  final Coordinate location;

  AppUser({
    required this.name,
    required this.mobile,
    required this.email,
    required this.password,
    required this.address,
    required this.location,
  });
}

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category; // e.g. "Dairy", "Beverages", "Sweets", "Bakery"
  final String imageUrl;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
  });
}

class Shop {
  final String id;
  final String name;
  final String category; // e.g., "Grocery", "Sweets", "Supermarket"
  final double rating;
  final int deliveryTimeMinutes;
  final double distanceKm;
  final String imageUrl;
  final List<MenuItem> menu;
  final Coordinate location;

  const Shop({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.deliveryTimeMinutes,
    required this.distanceKm,
    required this.imageUrl,
    required this.menu,
    required this.location,
  });
}

class CartItem {
  final MenuItem item;
  int quantity;

  CartItem({
    required this.item,
    this.quantity = 1,
  });

  double get total => item.price * quantity;
}

enum OrderStatus {
  placed,
  accepted,
  preparing,
  outForDelivery,
  delivered,
}

class Rider {
  final String name;
  final String vehicle;
  final String vehicleNumber;
  final double rating;
  final String phone;
  Coordinate currentPosition;

  Rider({
    required this.name,
    required this.vehicle,
    required this.vehicleNumber,
    required this.rating,
    required this.phone,
    required this.currentPosition,
  });
}

class OrderModel {
  final String id;
  final Shop shop;
  final List<CartItem> items;
  final double totalAmount;
  final double deliveryFee;
  final double tax;
  OrderStatus status;
  final Rider rider;
  final DateTime timestamp;
  final Coordinate customerLocation;
  Coordinate currentRiderPosition;

  OrderModel({
    required this.id,
    required this.shop,
    required this.items,
    required this.totalAmount,
    required this.deliveryFee,
    required this.tax,
    required this.status,
    required this.rider,
    required this.timestamp,
    required this.customerLocation,
    required this.currentRiderPosition,
  });

  double get grandTotal => totalAmount + deliveryFee + tax;
}
