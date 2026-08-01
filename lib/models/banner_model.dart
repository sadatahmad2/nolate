class BannerModel {
  final String id;
  final String merchantId;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String bannerType;
  final String actionType;
  final String? productId;
  final String? categoryId;
  final String? shopId;
  final String? offerId;
  final String? externalLink;
  final String? city;
  final int priority;

  BannerModel({
    required this.id,
    required this.merchantId,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    required this.bannerType,
    required this.actionType,
    this.productId,
    this.categoryId,
    this.shopId,
    this.offerId,
    this.externalLink,
    this.city,
    required this.priority,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      merchantId: json['merchant_id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      imageUrl: json['image_url'] as String,
      bannerType: json['banner_type'] as String,
      actionType: json['action_type'] as String,
      productId: json['product_id'] as String?,
      categoryId: json['category_id'] as String?,
      shopId: json['shop_id'] as String?,
      offerId: json['offer_id'] as String?,
      externalLink: json['external_link'] as String?,
      city: json['city'] as String?,
      priority: json['priority'] as int? ?? 0,
    );
  }
}
