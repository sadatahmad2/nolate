import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../providers/cart_provider.dart';
import '../models/models.dart';
import '../widgets/floating_cart_pill.dart';
import 'product_details_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _getFilteredProducts(ShopProvider shopProvider) {
    List<Map<String, dynamic>> categoryProducts = [];

    // Filter by Category
    for (var shop in shopProvider.shops) {
      for (var item in shop.menu) {
        final matchesCategory = widget.categoryId == 'All' ||
            item.category.toLowerCase().contains(widget.categoryId.toLowerCase()) ||
            (widget.categoryId == 'Grocery' && (item.category.toLowerCase().contains('grocery') || item.category.toLowerCase().contains('groceries'))) ||
            (widget.categoryId == 'Sweets' && (item.category.toLowerCase().contains('sweets') || item.category.toLowerCase().contains('sweet'))) ||
            (widget.categoryId == 'Gifts' && (item.category.toLowerCase().contains('gift') || item.category.toLowerCase().contains('gifts'))) ||
            (widget.categoryId == 'Books' && (item.category.toLowerCase().contains('book') || item.category.toLowerCase().contains('stationery')));

        if (matchesCategory) {
          categoryProducts.add({
            'product': item,
            'shop': shop,
          });
        }
      }
    }

    // Filter by Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      categoryProducts = categoryProducts.where((p) {
        final item = p['product'] as MenuItem;
        final shop = p['shop'] as Shop;
        return item.name.toLowerCase().contains(query) ||
               item.description.toLowerCase().contains(query) ||
               item.tags.toLowerCase().contains(query) ||
               item.brand.toLowerCase().contains(query) ||
               shop.name.toLowerCase().contains(query);
      }).toList();
    }

    // Sort by distance
    categoryProducts.sort((a, b) => (a['shop'] as Shop).distanceKm.compareTo((b['shop'] as Shop).distanceKm));
    
    return categoryProducts;
  }

  Widget _buildProductCard(
    BuildContext context,
    MenuItem item,
    Shop shop,
    CartProvider cart,
  ) {
    final cartItem = cart.items.values.firstWhere(
      (ci) => ci.item.id == item.id,
      orElse: () => CartItem(item: item, quantity: 0),
    );
    final int quantity = cartItem.quantity;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: item, shop: shop),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    item.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.access_time, size: 10, color: Colors.black87),
                        SizedBox(width: 4),
                        Text(
                          '20 MINS',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${item.price.toInt()}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black87),
                        ),
                        if (quantity > 0)
                          Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF166534),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => cart.removeItem(item.id),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.remove, color: Colors.white, size: 16),
                                  ),
                                ),
                                Text(
                                  '$quantity',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                InkWell(
                                  onTap: () => cart.addItem(item, shop),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.add, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          InkWell(
                            onTap: () => cart.addItem(item, shop),
                            child: Container(
                              height: 28,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF166534),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'ADD',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final filteredProducts = _getFilteredProducts(shopProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName.replaceAll('\n', ' '),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search in ${widget.categoryName.replaceAll('\n', ' ')}...',
                    hintStyle: const TextStyle(color: Colors.black38),
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),

              // Product Grid
              Expanded(
                child: shopProvider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
                    : filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text(
                                  'No products found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.only(left: 14, right: 14, top: 12, bottom: 100),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final productData = filteredProducts[index];
                              return _buildProductCard(
                                context,
                                productData['product'] as MenuItem,
                                productData['shop'] as Shop,
                                cart,
                              );
                            },
                          ),
              ),
            ],
          ),

          // Floating Cart Pill
          if (cart.itemCount > 0)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: const FloatingCartPill(),
            ),
        ],
      ),
    );
  }
}
