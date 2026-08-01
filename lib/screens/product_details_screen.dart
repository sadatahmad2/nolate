import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/floating_cart_pill.dart';

class ProductDetailsScreen extends StatefulWidget {
  final MenuItem product;
  final Shop shop;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.shop,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentImageIndex = 0;
  bool _isDescExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    
    // Check if item is in cart
    final cartItem = cart.items[widget.product.id];
    final quantity = cartItem?.quantity ?? 0;

    List<String> allImages = [];
    if (widget.product.imageUrls.isNotEmpty) {
      allImages = List.from(widget.product.imageUrls);
    } else if (widget.product.imageUrl.isNotEmpty) {
      allImages = [widget.product.imageUrl];
    }

    // Premium UI Redesign colors
    const Color primaryPurple = Color(0xFF059669); // Emerald Green
    const Color bgPurple = Color(0xFFF8FAFC); // Slate 50
    const Color lightPurpleBtn = Color(0xFFD1FAE5); // Emerald 100

    return Scaffold(
      backgroundColor: bgPurple,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            ),
          ),
        ),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, wishlist, child) {
              final isLiked = wishlist.isWishlisted(widget.product.id);
              return GestureDetector(
                onTap: () {
                  wishlist.toggleWishlist(widget.product, widget.shop);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isLiked ? 'Removed from Wishlist' : 'Added to Wishlist'),
                      backgroundColor: const Color(0xFF059669),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.black87,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.share_outlined, color: Colors.black87, size: 20),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              children: [
                // Top Image Section
                Container(
                  width: double.infinity,
                  height: 400,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle circle background
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryPurple.withOpacity(0.08),
                        ),
                      ),
                      
                      // Images
                      if (allImages.isNotEmpty)
                        PageView.builder(
                          itemCount: allImages.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImageViewer(
                                      imageUrls: allImages,
                                      initialIndex: index,
                                      heroTagPrefix: 'product_${widget.product.id}',
                                    ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: index == 0 ? 'product_${widget.product.id}' : 'product_${widget.product.id}_$index',
                                child: Padding(
                                  padding: const EdgeInsets.all(40.0),
                                  child: Image.network(
                                    allImages[index],
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, stack) => const Icon(Icons.image_not_supported, size: 100, color: Colors.black12),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      else
                        const Icon(Icons.fastfood, size: 100, color: Colors.black12),
                      
                      // Discount Tag
                      if (widget.product.discount > 0)
                        Positioned(
                          top: 100,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${widget.product.discount.toInt()}% OFF',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      
                      // Dot indicators instead of text (1/2)
                      if (allImages.length > 1)
                        Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              allImages.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _currentImageIndex == index ? 8 : 6,
                                height: _currentImageIndex == index ? 8 : 6,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index ? const Color(0xFF059669) : Colors.black26,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Main Details Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Delivery & Seller
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: primaryPurple.withOpacity(0.7)),
                                const SizedBox(width: 6),
                                Text('${widget.shop.deliveryTimeMinutes} mins delivery', style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.verified_user, size: 16, color: primaryPurple.withOpacity(0.7)),
                                const SizedBox(width: 6),
                                Text('Sold by ${widget.shop.name}', style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Title
                        Text(
                          widget.product.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
                        ),
                        if (widget.product.shortDescription.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.product.shortDescription,
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Tags (Unit & Stock)
                        Row(
                          children: [
                            if (widget.product.unit.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: lightPurpleBtn,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.scale_outlined, size: 14, color: primaryPurple),
                                    const SizedBox(width: 4),
                                    Text(widget.product.unit, style: const TextStyle(fontSize: 12, color: primaryPurple, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            if (widget.product.unit.isNotEmpty) const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.product.stock > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.circle, size: 8, color: widget.product.stock > 0 ? Colors.green : Colors.red),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.product.stock > 0 ? 'In Stock' : 'Out of Stock',
                                    style: TextStyle(fontSize: 12, color: widget.product.stock > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),

                        // Pricing & Add button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${widget.product.price.toInt()}',
                                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                                      ),
                                      if (widget.product.mrp > widget.product.price) ...[
                                        const SizedBox(width: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text(
                                            '₹${widget.product.mrp.toInt()}',
                                            style: const TextStyle(fontSize: 14, color: Colors.black45, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text(
                                            '(${widget.product.discount.toInt()}% OFF)',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                  if (widget.product.mrp > widget.product.price)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'You save ₹${(widget.product.mrp - widget.product.price).toInt()}',
                                        style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Quantity Controls
                            Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: primaryPurple.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: quantity > 0
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 18, color: primaryPurple),
                                          onPressed: () => cart.removeSingleItem(widget.product.id),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                        ),
                                        Text(
                                          '$quantity',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 18, color: primaryPurple),
                                          onPressed: () {
                                            if (widget.product.stock > 0 && quantity >= widget.product.stock) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max stock reached')));
                                              return;
                                            }
                                            final added = cart.addItem(widget.product, widget.shop);
                                            if (!added) _showDifferentShopDialog(context, cart, widget.product, widget.shop);
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                        ),
                                      ],
                                    )
                                  : InkWell(
                                      onTap: () {
                                        if (widget.product.stock <= 0) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product is out of stock')));
                                          return;
                                        }
                                        final added = cart.addItem(widget.product, widget.shop);
                                        if (!added) _showDifferentShopDialog(context, cart, widget.product, widget.shop);
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                                        child: Center(
                                          child: Text('ADD', style: TextStyle(color: primaryPurple, fontWeight: FontWeight.w800, fontSize: 16)),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),

                        // Offers card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: lightPurpleBtn, borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.local_offer, size: 18, color: primaryPurple),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Offers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    SizedBox(height: 2),
                                    Text('Get extra 5% off on orders above ₹499', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black38),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Product Details Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Product Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildGridDetail(Icons.grid_view_rounded, 'Category', widget.product.category)),
                            Expanded(child: _buildGridDetail(Icons.access_time_rounded, 'Delivery Time', '${widget.shop.deliveryTimeMinutes} minutes')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildGridDetail(Icons.verified, 'Brand', widget.product.brand.isNotEmpty ? widget.product.brand : 'Generic')),
                            Expanded(child: _buildGridDetail(Icons.refresh, 'Return Policy', 'Not returnable')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildGridDetail(Icons.public, 'Country of Origin', widget.product.countryOfOrigin.isNotEmpty ? widget.product.countryOfOrigin : 'India')),
                            Expanded(child: _buildGridDetail(Icons.storefront, 'Sold by', widget.shop.name)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // About this product
                if (widget.product.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('About this product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                          const SizedBox(height: 12),
                          Text(
                            widget.product.description,
                            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                            maxLines: _isDescExpanded ? null : 3,
                            overflow: _isDescExpanded ? null : TextOverflow.fade,
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
                            child: Row(
                              children: [
                                Text(_isDescExpanded ? 'Read less' : 'Read more', style: const TextStyle(color: primaryPurple, fontWeight: FontWeight.bold, fontSize: 13)),
                                Icon(_isDescExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: primaryPurple, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // You may also like
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('You may also like', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                          Text('See all', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryPurple.withOpacity(0.8))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: widget.shop.menu.take(5).map((item) {
                            if (item.id == widget.product.id) return const SizedBox.shrink();
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailsScreen(product: item, shop: widget.shop),
                                  ),
                                );
                              },
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Consumer<WishlistProvider>(
                                          builder: (context, wishlist, child) {
                                            final isLiked = wishlist.isWishlisted(item.id);
                                            return GestureDetector(
                                              onTap: () {
                                                wishlist.toggleWishlist(item, widget.shop);
                                              },
                                              child: Icon(
                                                isLiked ? Icons.favorite : Icons.favorite_border,
                                                size: 16,
                                                color: isLiked ? Colors.red : Colors.black38,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    Center(
                                      child: Image.network(
                                        item.imageUrl.isNotEmpty ? item.imageUrl : 'https://via.placeholder.com/150',
                                        height: 80,
                                        fit: BoxFit.contain,
                                        errorBuilder: (c,e,s) => const Icon(Icons.image, size: 80, color: Colors.black12),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(item.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text('₹${item.price.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom fixed Add to Cart bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('₹${widget.product.price.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
                        Row(
                          children: const [
                            Text('View Price Details', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.black54),
                          ],
                        ),
                      ],
                    ),
                    
                    ElevatedButton.icon(
                      onPressed: () {
                        if (widget.product.stock <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product is out of stock')));
                          return;
                        }
                        final added = cart.addItem(widget.product, widget.shop);
                        if (!added) _showDifferentShopDialog(context, cart, widget.product, widget.shop);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                      label: const Text('Add to Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (cart.itemCount > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 100, // Above the Add to Cart bar
              child: const Center(
                child: FloatingCartPill(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridDetail(IconData icon, String title, String value) {
    const Color primaryPurple = Color(0xFF059669);
    const Color lightPurpleBtn = Color(0xFFD1FAE5);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: lightPurpleBtn, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: primaryPurple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: title == 'Sold by' ? primaryPurple : Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  void _showDifferentShopDialog(BuildContext context, CartProvider cart, MenuItem product, Shop shop) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace cart item?'),
        content: const Text('Your cart contains items from another shop. Do you want to discard the selection and add items from this shop?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              cart.forceAddItem(product, shop);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A35CA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Replace', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String heroTagPrefix;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    required this.heroTagPrefix,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: index == 0 ? widget.heroTagPrefix : '${widget.heroTagPrefix}_$index',
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => const Icon(Icons.image_not_supported, size: 100, color: Colors.white30),
                  ),
                ),
              );
            },
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 10 : 8,
                    height: _currentIndex == index ? 10 : 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? Colors.white : Colors.white.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
