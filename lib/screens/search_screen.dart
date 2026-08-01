import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/shop_provider.dart';
import '../providers/cart_provider.dart';
import '../models/models.dart';
import 'product_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _recentSearches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
      _isLoading = false;
    });
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    
    // Remove if already exists to move to top
    searches.removeWhere((q) => q.toLowerCase() == query.trim().toLowerCase());
    
    // Insert at top
    searches.insert(0, query.trim());
    
    // Keep only top 10
    if (searches.length > 10) {
      searches.removeLast();
    }

    await prefs.setStringList('recent_searches', searches);
    setState(() {
      _recentSearches = searches;
    });
  }

  Future<void> _removeSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    searches.remove(query);
    await prefs.setStringList('recent_searches', searches);
    setState(() {
      _recentSearches = searches;
    });
  }

  List<Map<String, dynamic>> _getSearchResults(ShopProvider shopProvider) {
    if (_searchQuery.trim().isEmpty) return [];

    final query = _searchQuery.toLowerCase();
    List<Map<String, dynamic>> results = [];

    for (final shop in shopProvider.shops) {
      // If shop name matches, add all products
      if (shop.name.toLowerCase().contains(query)) {
        for (final item in shop.menu) {
          results.add({'product': item, 'shop': shop});
        }
        continue; // Prevent duplicates if both shop and item match
      }

      // Check item matches
      for (final item in shop.menu) {
        if (item.name.toLowerCase().contains(query) || 
            item.description.toLowerCase().contains(query) ||
            item.tags.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query) ||
            item.brand.toLowerCase().contains(query)) {
          results.add({'product': item, 'shop': shop});
        }
      }
    }

    // Sort by distance (assuming ShopProvider calculates distance or just defaulting)
    results.sort((a, b) => (a['shop'] as Shop).distanceKm.compareTo((b['shop'] as Shop).distanceKm));
    
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final searchResults = _getSearchResults(shopProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'Search for milk, bread, snacks...',
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 15),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.black45, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : const Icon(Icons.search, color: Colors.black26),
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          onSubmitted: (val) {
            _saveSearch(val);
          },
          textInputAction: TextInputAction.search,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : _searchQuery.trim().isEmpty
              ? _buildRecentSearches()
              : _buildSearchResults(searchResults, cart),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.black12),
            SizedBox(height: 16),
            Text(
              'What are you craving?',
              style: TextStyle(fontSize: 18, color: Colors.black45, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Recent Searches',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentSearches.map((query) {
            return InkWell(
              onTap: () {
                _searchController.text = query;
                setState(() {
                  _searchQuery = query;
                });
                _saveSearch(query);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history, size: 14, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(query, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeSearch(query),
                      child: const Icon(Icons.close, size: 14, color: Colors.black38),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults(List<Map<String, dynamic>> results, CartProvider cart) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.black12),
            const SizedBox(height: 16),
            Text(
              'No items found for "$_searchQuery"',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final productData = results[index];
        return _buildProductCard(
          context,
          productData['product'] as MenuItem,
          productData['shop'] as Shop,
          cart,
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, MenuItem item, Shop shop, CartProvider cart) {
    final cartItem = cart.items[item.id];
    final quantity = cartItem?.quantity ?? 0;
    
    return GestureDetector(
      onTap: () {
        // Save the search when they click a product
        _saveSearch(_searchQuery);
        
        Navigator.of(context).push(
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image & Timer
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  child: Image.network(
                    item.imageUrl.isNotEmpty ? item.imageUrl : 'https://via.placeholder.com/150',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 120,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_filled, size: 12, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text(
                          '${shop.deliveryTimeMinutes} MINS',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
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
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.unit.isNotEmpty ? item.unit : '1 item',
                      style: const TextStyle(color: Colors.black54, fontSize: 11),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${item.price.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87),
                            ),
                            if (item.mrp > item.price)
                              Text(
                                '₹${item.mrp.toInt()}',
                                style: const TextStyle(
                                  color: Colors.black45,
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        
                        // Add Button
                        if (quantity > 0)
                          Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () => cart.removeSingleItem(item.id),
                                ),
                                Text('$quantity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () {
                                    final added = cart.addItem(item, shop);
                                    if (!added) _showDifferentShopDialog(context, cart, item, shop);
                                  },
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            height: 32,
                            width: 60,
                            child: OutlinedButton(
                              onPressed: () {
                                final added = cart.addItem(item, shop);
                                if (!added) _showDifferentShopDialog(context, cart, item, shop);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF059669),
                                side: const BorderSide(color: Color(0xFF059669), width: 1),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
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
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Replace', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
