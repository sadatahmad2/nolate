import 'dart:math';

class Coordinate {
  final double x; // From 0.0 to 1.0 (relative canvas width)
  final double y; // From 0.0 to 1.0 (relative canvas height)

  const Coordinate(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  factory Coordinate.fromJson(Map<String, dynamic> json) => Coordinate(json['x'] ?? 0.0, json['y'] ?? 0.0);

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
  final List<String> imageUrls;
  final String brand;
  final double mrp;
  final double discount;
  final String unit;
  final String hsnCode;
  final String sku;
  final String countryOfOrigin;
  final String shortDescription;
  final String subCategory;
  final String tags;
  final int stock;
  final String stockUnit;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.imageUrls = const [],
    this.brand = '',
    this.mrp = 0.0,
    this.discount = 0.0,
    this.unit = '',
    this.hsnCode = '',
    this.sku = '',
    this.countryOfOrigin = '',
    this.shortDescription = '',
    this.subCategory = '',
    this.tags = '',
    this.stock = 0,
    this.stockUnit = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'category': category,
    'imageUrl': imageUrl,
    'imageUrls': imageUrls,
    'brand': brand,
    'mrp': mrp,
    'discount': discount,
    'unit': unit,
    'hsnCode': hsnCode,
    'sku': sku,
    'countryOfOrigin': countryOfOrigin,
    'shortDescription': shortDescription,
    'subCategory': subCategory,
    'tags': tags,
    'stock': stock,
    'stockUnit': stockUnit,
  };

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    price: (json['price'] ?? 0.0).toDouble(),
    category: json['category'] ?? '',
    imageUrl: json['imageUrl'] ?? json['image_url'] ?? '',
    imageUrls: (json['imageUrls'] as List<dynamic>? ?? json['image_urls'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    brand: json['brand'] ?? '',
    mrp: (json['mrp'] ?? 0.0).toDouble(),
    discount: (json['discount'] ?? 0.0).toDouble(),
    unit: json['unit'] ?? '',
    hsnCode: json['hsnCode'] ?? json['hsn_code'] ?? '',
    sku: json['sku'] ?? '',
    countryOfOrigin: json['countryOfOrigin'] ?? json['country_of_origin'] ?? '',
    shortDescription: json['shortDescription'] ?? json['short_description'] ?? '',
    subCategory: json['subCategory'] ?? json['sub_category'] ?? '',
    tags: json['tags'] ?? '',
    stock: json['stock'] ?? 0,
    stockUnit: json['stockUnit'] ?? json['stock_unit'] ?? '',
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'rating': rating,
    'deliveryTimeMinutes': deliveryTimeMinutes,
    'distanceKm': distanceKm,
    'imageUrl': imageUrl,
    'menu': menu.map((m) => m.toJson()).toList(),
    'location': location.toJson(),
  };

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    category: json['category'] ?? '',
    rating: (json['rating'] ?? 0.0).toDouble(),
    deliveryTimeMinutes: json['deliveryTimeMinutes'] ?? 0,
    distanceKm: (json['distanceKm'] ?? 0.0).toDouble(),
    imageUrl: json['imageUrl'] ?? '',
    menu: (json['menu'] as List<dynamic>? ?? []).map((m) => MenuItem.fromJson(m)).toList(),
    location: Coordinate.fromJson(json['location'] ?? {}),
  );
}

class CartItem {
  final MenuItem item;
  int quantity;

  CartItem({
    required this.item,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'item': item.toJson(),
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    item: MenuItem.fromJson(json['item'] ?? {}),
    quantity: json['quantity'] ?? 1,
  );

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
  Rider rider;
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

class WishlistItem {
  final MenuItem item;
  final Shop shop;
  final DateTime addedAt;

  WishlistItem({
    required this.item,
    required this.shop,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'item': item.toJson(),
    'shop': shop.toJson(),
    'addedAt': addedAt.toIso8601String(),
  };

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
    item: MenuItem.fromJson(json['item']),
    shop: Shop.fromJson(json['shop']),
    addedAt: json['addedAt'] != null ? DateTime.parse(json['addedAt']) : DateTime.now(),
  );
}
