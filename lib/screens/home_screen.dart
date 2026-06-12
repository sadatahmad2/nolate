import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../models/mock_data.dart';
import '../models/models.dart';
import 'shop_details_screen.dart';
import 'tracking_screen.dart';
import 'splash_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final int _activeCarouselIndex = 0;
  int _selectedNavIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Shop> get _filteredShops {
    return mockShops.where((shop) {
      final matchesCategory = _selectedCategory == 'All' ||
          shop.category.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
          (_selectedCategory == 'Grocery' && shop.category.toLowerCase().contains('grocery')) ||
          (_selectedCategory == 'Sweets' && shop.category.toLowerCase().contains('sweets'));

      final matchesSearch = shop.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          shop.category.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final order = Provider.of<OrderProvider>(context);
    final theme = Theme.of(context);

    final user = auth.currentUser;

    if (user == null) {
      return const SplashScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light Background
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Zoodo Custom Header
                _buildZoodoHeader(context, user, auth),

                // Tab Content
                Expanded(
                  child: _selectedNavIndex == 0
                      ? _buildHomeTab(context, theme, order, cart)
                      : _selectedNavIndex == 1
                          ? _buildOrderAgainTab(context, order)
                          : _selectedNavIndex == 2
                              ? _buildCategoriesTab(context, theme, cart)
                              : _buildFoodTab(context),
                ),
              ],
            ),

            // Floating Green Cart Pill
            if (cart.itemCount > 0)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _buildFloatingCartPill(context, cart),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildZoodoBottomNav(context, cart, auth),
    );
  }

  // ─── HOME TAB ───
  Widget _buildHomeTab(BuildContext context, ThemeData theme, OrderProvider order, CartProvider cart) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      color: const Color(0xFF0C831F),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildCircularCategories(),
            if (order.activeOrder != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: _buildActiveOrderBanner(context, order.activeOrder!),
              ),
            ],
            _buildEpicSaleCarousel(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Stores Near You',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${_filteredShops.length} stores found',
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_filteredShops.isEmpty)
                    _buildEmptyState()
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredShops.length,
                      itemBuilder: (context, index) {
                        final shop = _filteredShops[index];
                        return _buildShopCard(context, shop, theme);
                      },
                    ),
                ],
              ),
            ),
            _buildTopSelectionSection(context, cart),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ─── ORDER AGAIN TAB ───
  Widget _buildOrderAgainTab(BuildContext context, OrderProvider order) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Orders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          if (order.activeOrder != null) ...[
            _buildOrderCard(
              context,
              icon: Icons.delivery_dining_rounded,
              title: 'Active Order',
              subtitle: 'Order #${order.activeOrder!.id.substring(0, 8)} • ${order.activeOrder!.status}',
              color: const Color(0xFF0C831F),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrackingScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          _buildOrderCard(
            context,
            icon: Icons.replay_rounded,
            title: 'Reorder your favourites',
            subtitle: 'Quickly add items from your past orders',
            color: const Color(0xFF0C831F),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No past orders yet. Start shopping!'),
                  backgroundColor: Color(0xFF0C831F),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long_rounded, size: 80, color: Colors.black.withValues(alpha: 0.08)),
                const SizedBox(height: 12),
                const Text(
                  'Your order history will appear here',
                  style: TextStyle(color: Colors.black38, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  // ─── CATEGORIES TAB ───
  Widget _buildCategoriesTab(BuildContext context, ThemeData theme, CartProvider cart) {
    final allCategories = [
      {'id': 'All', 'label': 'All Stores', 'icon': Icons.storefront_rounded},
      {'id': 'Grocery', 'label': 'Grocery', 'icon': Icons.local_grocery_store_rounded},
      {'id': 'Sweets', 'label': 'Sweets & Bakery', 'icon': Icons.cake_rounded},
      {'id': 'Snacks', 'label': 'Snacks & Chips', 'icon': Icons.fastfood_rounded},
      {'id': 'Dairy', 'label': 'Dairy & Breakfast', 'icon': Icons.egg_rounded},
      {'id': 'Beverages', 'label': 'Beverages', 'icon': Icons.local_cafe_rounded},
      {'id': 'Personal', 'label': 'Personal Care', 'icon': Icons.clean_hands_rounded},
      {'id': 'Home', 'label': 'Home & Kitchen', 'icon': Icons.kitchen_rounded},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shop by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: allCategories.length,
            itemBuilder: (context, index) {
              final cat = allCategories[index];
              final catId = cat['id'] as String;
              final isSelected = _selectedCategory == catId;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedCategory = catId;
                    _selectedNavIndex = 0; // Go back to Home with filter
                  });
                },
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE6F4EA) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0C831F) : Colors.black12,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        cat['icon'] as IconData,
                        color: isSelected ? const Color(0xFF0C831F) : Colors.black45,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat['label'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF0C831F) : Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Popular Stores',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mockShops.length,
            itemBuilder: (context, index) {
              final shop = mockShops[index];
              return _buildShopCard(context, shop, Theme.of(context));
            },
          ),
        ],
      ),
    );
  }

  // ─── FOOD TAB ───
  Widget _buildFoodTab(BuildContext context) {
    final foodShops = mockShops.where((s) =>
        s.category.toLowerCase().contains('food') ||
        s.category.toLowerCase().contains('restaurant') ||
        s.category.toLowerCase().contains('sweets')).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0C831F), Color(0xFF0C513F)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.restaurant_rounded, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zoodo Food',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Order delicious food delivered in minutes!',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Food & Restaurant Stores',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          if (foodShops.isEmpty)
            // Show all shops as food suggestions
            ...mockShops.map((shop) => _buildShopCard(context, shop, Theme.of(context)))
          else
            ...foodShops.map((shop) => _buildShopCard(context, shop, Theme.of(context))),
        ],
      ),
    );
  }

  Widget _buildZoodoHeader(BuildContext context, AppUser user, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12, top: 12, left: 14, right: 14),
      color: const Color(0xFF0C513F), // Forest Green
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Delivery Status & Location Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Zoodo in ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          '15 minutes',
                          style: TextStyle(
                            color: Color(0xFFF7D108), // Brand Yellow
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '850 m away',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined, color: Color(0xFFF7D108), size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              user.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Wallet & Profile Icons
              Row(
                children: [
                  // Wallet representation
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wallet, color: Color(0xFFF7D108), size: 14),
                        SizedBox(width: 4),
                        Text(
                          '₹0',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Profile icon that opens dialog
                  GestureDetector(
                    onTap: () => _showProfileDialog(context, user, auth),
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFF7D108),
                      child: Icon(Icons.person, color: Color(0xFF0C513F), size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: Colors.black45, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search "milk", "bread", or shops...',
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.black45, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                const Icon(Icons.mic_none_outlined, color: Colors.black45, size: 20),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context, AppUser user, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Header with Yellow-to-White gradient
              Container(
                padding: const EdgeInsets.only(top: 10, bottom: 20, left: 20, right: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF7D108), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0xFF0C513F),
                          child: Icon(Icons.person, color: Colors.white, size: 32),
                        ),
                         const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Account',
                                style: TextStyle(
                                  color: Color(0xFF0C513F),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.name,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user.mobile,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Active Cards / Information
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA), // Soft Mint Green card
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCEEAD6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFF0C831F), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Zoodo Premium Member',
                              style: TextStyle(
                                color: Color(0xFF0C513F),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Enjoy free deliveries on orders above ₹199',
                              style: TextStyle(
                                color: const Color(0xFF0C513F).withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Option list
              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined, color: Colors.black87),
                title: const Text('Your Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1, color: Colors.black12),
              ListTile(
                leading: const Icon(Icons.home_outlined, color: Colors.black87),
                title: const Text('Address Book', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(user.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1, color: Colors.black12),
              ListTile(
                leading: const Icon(Icons.support_agent_rounded, color: Colors.black87),
                title: const Text('Customer Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1, color: Colors.black12),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  auth.logout();
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }



  Widget _buildFloatingCartPill(BuildContext context, CartProvider cart) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CartScreen()),
        );
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0C831F), // Zoodo green
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              "${cart.itemCount} Item${cart.itemCount > 1 ? 's' : ''} • ₹${cart.grandTotal.toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            const Text(
              'View Cart',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  void _showConflictDialog(BuildContext context, CartProvider cart, MenuItem item, Shop shop) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Replace Cart Items?', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          content: Text(
            'Your cart contains items from "${cart.currentShop?.name}". Do you want to discard them and add items from "${shop.name}" instead?',
            style: const TextStyle(color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.black45)),
            ),
            ElevatedButton(
              onPressed: () {
                cart.forceAddItem(item, shop);
                Navigator.of(context).pop();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C831F)),
              child: const Text('Clear & Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCircularCategories() {
    final categories = [
      {'id': 'All', 'label': 'For You', 'icon': Icons.shopping_bag_outlined, 'color': const Color(0xFF0C831F)},
      {'id': 'Grocery', 'label': 'Grocery', 'icon': Icons.local_grocery_store_outlined, 'color': const Color(0xFF0C831F)},
      {'id': 'Sweets', 'label': 'Sweets', 'icon': Icons.cake_outlined, 'color': const Color(0xFF0C831F)},
      {'id': 'Snacks', 'label': 'Snacks', 'icon': Icons.fastfood_outlined, 'color': const Color(0xFF0C831F)},
      {'id': 'Dairy', 'label': 'Dairy', 'icon': Icons.local_cafe_outlined, 'color': const Color(0xFF0C831F)},
    ];

    return Container(
      color: Colors.white,
      height: 96,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final catId = cat['id'] as String;
          final isSelected = _selectedCategory == catId;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = catId;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE6F4EA) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0C831F) : Colors.black12,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      color: isSelected ? const Color(0xFF0C831F) : Colors.black54,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? const Color(0xFF0C831F) : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEpicSaleCarousel() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          // Banner Frame inspired by Zoodo style
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE6F4EA), Color(0xFFCEEAD6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Stack(
              children: [
                // Sale branding decoration
                const Positioned(
                  left: 20,
                  top: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUPER SAVER SALE',
                        style: TextStyle(
                          color: Color(0xFF084335),
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Up to 50% Off on Daily Essentials',
                        style: TextStyle(
                          color: Color(0xFF0C831F),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Machine / appliance graphic
                Positioned(
                  right: 16,
                  top: 10,
                  bottom: 10,
                  width: 90,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.shopping_basket_rounded, color: Color(0xFF0C831F), size: 44),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Dot indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                width: index == _activeCarouselIndex ? 14 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: index == _activeCarouselIndex
                      ? const Color(0xFF0C831F)
                      : Colors.black12,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, Shop shop, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ShopDetailsScreen(shop: shop),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 2.3,
              child: Image.network(
                shop.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[100],
                  child: const Icon(Icons.storefront_rounded, size: 40, color: Colors.black26),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        shop.name,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              shop.rating.toString(),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shop.category,
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                  const Divider(color: Colors.black12, height: 16),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: Colors.black38, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${shop.deliveryTimeMinutes} mins',
                        style: const TextStyle(color: Colors.black54, fontSize: 11),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.directions_bike, color: Colors.black38, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${shop.distanceKm} km away',
                        style: const TextStyle(color: Colors.black54, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSelectionSection(BuildContext context, CartProvider cart) {
    // Collect some products from all shops
    final List<MapEntry<Shop, MenuItem>> featuredItems = [];
    for (var shop in mockShops) {
      for (var item in shop.menu) {
        if (featuredItems.length < 8) {
          featuredItems.add(MapEntry(shop, item));
        }
      }
    }

    return Container(
      color: const Color(0xFFF3F4F6), // Match scaffold
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bestsellers',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0C831F), size: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 186,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: featuredItems.length,
              itemBuilder: (context, index) {
                final entry = featuredItems[index];
                final shop = entry.key;
                final item = entry.value;
                final cartItem = cart.items[item.id];
                final isAdded = cartItem != null;
                final quantity = cartItem?.quantity ?? 0;

                return Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAdded ? const Color(0xFF0C831F) : Colors.black.withValues(alpha: 0.05),
                      width: isAdded ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.fastfood, color: Colors.black12),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  shop.name,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${item.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                // Mini ADD/quantity selector
                                if (!isAdded)
                                  GestureDetector(
                                    onTap: () {
                                      final added = cart.addItem(item, shop);
                                      if (!added) {
                                        _showConflictDialog(context, cart, item, shop);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF0C831F), width: 1.0),
                                      ),
                                      child: const Text(
                                        'ADD',
                                        style: TextStyle(
                                          color: Color(0xFF0C831F),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0C831F),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => cart.removeSingleItem(item.id),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 6.0),
                                            child: Icon(Icons.remove, size: 10, color: Colors.white),
                                          ),
                                        ),
                                        Text(
                                          quantity.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => cart.addItem(item, shop),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 6.0),
                                            child: Icon(Icons.add, size: 10, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderBanner(BuildContext context, OrderModel activeOrder) {
    Color statusColor = const Color(0xFF0C831F); // Zoodo Green status
    String statusText = 'Preparing your order';

    if (activeOrder.status == OrderStatus.placed) {
      statusText = 'Order Placed';
    } else if (activeOrder.status == OrderStatus.accepted) {
      statusText = 'Order Accepted';
    } else if (activeOrder.status == OrderStatus.outForDelivery) {
      statusText = 'Out for Delivery';
    } else if (activeOrder.status == OrderStatus.delivered) {
      statusColor = Colors.green;
      statusText = 'Order Delivered';
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const TrackingScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.08),
              child: Icon(Icons.delivery_dining, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${activeOrder.id} • ${activeOrder.shop.name}',
                    style: const TextStyle(color: Colors.black38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black38, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 30.0),
        child: Column(
          children: [
            Icon(Icons.storefront_outlined, color: Colors.black12, size: 50),
            SizedBox(height: 12),
            Text(
              'No matching stores found',
              style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoodoBottomNav(BuildContext context, CartProvider cart, AuthProvider auth) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isActive: _selectedNavIndex == 0,
            activeColor: const Color(0xFF0C831F),
            onTap: () {
              setState(() { _selectedNavIndex = 0; });
            },
          ),
          _buildBottomNavItem(
            icon: Icons.history_rounded,
            label: 'Order Again',
            isActive: _selectedNavIndex == 1,
            onTap: () {
              setState(() { _selectedNavIndex = 1; });
            },
          ),
          _buildBottomNavItem(
            icon: Icons.grid_view_rounded,
            label: 'Categories',
            isActive: _selectedNavIndex == 2,
            onTap: () {
              setState(() { _selectedNavIndex = 2; });
            },
          ),
          _buildBottomNavItem(
            icon: Icons.restaurant_rounded,
            label: 'Food',
            isActive: _selectedNavIndex == 3,
            onTap: () {
              setState(() { _selectedNavIndex = 3; });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final color = isActive ? (activeColor ?? const Color(0xFF0C831F)) : Colors.black38;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
