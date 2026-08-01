import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../models/models.dart';
import '../providers/shop_provider.dart';
import '../providers/banner_provider.dart';
import '../providers/wishlist_provider.dart';
import '../utils/receipt_generator.dart';
import 'shop_details_screen.dart';
import 'tracking_screen.dart';
import 'splash_screen.dart';
import 'cart_screen.dart';
import 'zoodo_money_screen.dart';
import 'profile_screen.dart';
import 'location_picker_sheet.dart';
import 'product_details_screen.dart';
import 'search_screen.dart';
import 'category_screen.dart';
import '../widgets/floating_cart_pill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'placeholder_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  int _activeCarouselIndex = 0;
  int _selectedNavIndex = 0;
  String? _currentAddress;

  final GlobalKey _productsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final bannerProvider = Provider.of<BannerProvider>(context, listen: false);
      bannerProvider.fetchBanners();
    });
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final shops = Provider.of<ShopProvider>(context).shops;
    List<Map<String, dynamic>> allProducts = [];
    
    for (var shop in shops) {
      for (var item in shop.menu) {
        final matchesCategory = _selectedCategory == 'All' ||
            item.category.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
            (_selectedCategory == 'Grocery' && (item.category.toLowerCase().contains('grocery') || item.category.toLowerCase().contains('groceries'))) ||
            (_selectedCategory == 'Sweets' && (item.category.toLowerCase().contains('sweets') || item.category.toLowerCase().contains('sweet'))) ||
            (_selectedCategory == 'Gifts' && (item.category.toLowerCase().contains('gift') || item.category.toLowerCase().contains('gifts'))) ||
            (_selectedCategory == 'Books' && (item.category.toLowerCase().contains('book') || item.category.toLowerCase().contains('stationery')));

        if (matchesCategory) {
          allProducts.add({
            'product': item,
            'shop': shop,
          });
        }
      }
    }
    
    // Sort by distance so nearest products are on top
    allProducts.sort((a, b) => (a['shop'] as Shop).distanceKm.compareTo((b['shop'] as Shop).distanceKm));
    
    return allProducts;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final order = Provider.of<OrderProvider>(context);
    final shopProvider = Provider.of<ShopProvider>(context);
    final theme = Theme.of(context);

    // Support both Google (Supabase) and legacy local auth
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final user = auth.currentUser;
    final isLoggedIn = user != null || supabaseUser != null;

    if (!isLoggedIn) {
      return const SplashScreen();
    }

    // Use a guest user name if logged in via Google
    final displayUser = user ?? AppUser(
      name: supabaseUser?.userMetadata?['full_name'] ?? supabaseUser?.userMetadata?['name'] ?? 'Guest',
      mobile: '',
      email: supabaseUser?.email ?? '',
      password: '',
      address: 'Set your location',
      location: const Coordinate(0.5, 0.5),
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (_selectedNavIndex != 3 && _selectedNavIndex != 4) _buildZoodoHeader(context, displayUser, auth),
                Expanded(
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    child: () {
                      switch (_selectedNavIndex) {
                        case 0: return _buildHomeTab(context, theme, order, cart, shopProvider);
                        case 1: return _buildOrderAgainTab(context, order);
                        case 2: return _buildCategoriesTab(context, theme, cart);
                        case 3: return _buildFoodTab(context);
                        case 4: return _buildGiftTab(context);
                        default: return const SizedBox.shrink();
                      }
                    }(),
                  ),
                ),
              ],
            ),
            if (cart.itemCount > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: FloatingCartPill(
                    backgroundColor: _selectedNavIndex == 4 
                        ? const Color(0xFF8B0021) 
                        : const Color(0xFF166534),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildZoodoBottomNav(context, cart, auth),
        ),

      ],
    );
  }

  // ─── HOME TAB ───
  Widget _buildHomeTab(BuildContext context, ThemeData theme, OrderProvider order, CartProvider cart, ShopProvider shopProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        final bannerProvider = Provider.of<BannerProvider>(context, listen: false);
        await Future.wait([
          shopProvider.refresh(),
          bannerProvider.fetchBanners(),
        ]);
      },
      color: const Color(0xFF059669),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildEpicSaleCarousel(),
            _buildCategoriesGrid(),
            _buildTrustMarkers(),
            
            if (order.activeOrder != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: _buildActiveOrderBanner(context, order.activeOrder!),
              ),
            ],

            _buildHotDealsCarousel(),

            Container(
              key: _productsKey,
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Products Near You',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF166534),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.location_on, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('On Map', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              children: const [
                                Text('Sort', style: TextStyle(color: Color(0xFF166534), fontSize: 11, fontWeight: FontWeight.bold)),
                                SizedBox(width: 4),
                                Icon(Icons.swap_vert, color: Color(0xFF166534), size: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (shopProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF059669), strokeWidth: 2)),
                    )
                  else if (_filteredProducts.isEmpty)
                    _buildEmptyState()
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final productData = _filteredProducts[index];
                        return _buildProductCard(
                          context,
                          productData['product'] as MenuItem,
                          productData['shop'] as Shop,
                          cart,
                        );
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
              color: const Color(0xFF059669),
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
            color: const Color(0xFF059669),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No past orders yet. Start shopping!'),
                  backgroundColor: Color(0xFF059669),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          if (order.orderHistory.isEmpty)
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
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.orderHistory.length,
              itemBuilder: (context, index) {
                final hist = order.orderHistory[index];
                // Don't show active order in history if it's currently active (unless it's delivered/cancelled)
                if (order.activeOrder != null && order.activeOrder!.id == hist.id && hist.status != OrderStatus.delivered) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      _buildOrderCard(
                        context,
                        icon: Icons.history_rounded,
                        title: 'Order from ${hist.shop.name}',
                        subtitle: 'Total: ₹${(hist.totalAmount + hist.deliveryFee + hist.tax).toStringAsFixed(0)} • ${hist.status.name.toUpperCase()}',
                        color: Colors.grey.shade600,
                        onTap: () {
                          // Optionally show details or reorder
                        },
                      ),
                      if (hist.status == OrderStatus.delivered)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () async {
                              await ReceiptGenerator.generateAndDownloadReceipt(
                                orderId: hist.id,
                                customerName: 'Customer',
                                customerPhone: '',
                                customerAddress: '',
                                shopName: hist.shop.name,
                                items: hist.items.map((i) => {
                                  'name': i.item.name,
                                  'quantity': i.quantity,
                                  'price': i.item.price,
                                }).toList(),
                                subtotal: hist.totalAmount,
                                tax: hist.tax,
                                deliveryFee: hist.deliveryFee,
                                total: hist.totalAmount + hist.tax + hist.deliveryFee,
                                date: hist.timestamp,
                                riderName: hist.rider.name,
                              );
                            },
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Download Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
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
      {'id': 'Grocery', 'label': 'Grocery', 'time': '10-20 min', 'imageUrl': 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Fruits', 'label': 'Fruits &\nVegetables', 'time': '10-20 min', 'imageUrl': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Cakes', 'label': 'Cakes', 'time': '30 min', 'imageUrl': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Gifts', 'label': 'Gifts', 'time': '30 min', 'imageUrl': 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Flowers', 'label': 'Flowers', 'time': '15-20 min', 'imageUrl': 'https://images.unsplash.com/photo-1563241527-3004b7be0ffd?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Dairy', 'label': 'Dairy &\nBreakfast', 'time': '10-20 min', 'imageUrl': 'https://images.unsplash.com/photo-1628088062854-d1870b4553da?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Snacks', 'label': 'Snacks &\nBeverages', 'time': '10-20 min', 'imageUrl': 'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Food', 'label': 'Food', 'time': '20-30 min', 'imageUrl': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Medicines', 'label': 'Medicines', 'time': '15-25 min', 'imageUrl': 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Books', 'label': 'Books &\nStationery', 'time': '30-40 min', 'imageUrl': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Electronics', 'label': 'Electronics', 'time': '40-50 min', 'imageUrl': 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Pets', 'label': 'Pet Care', 'time': '20-30 min', 'imageUrl': 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Personal Care', 'label': 'Personal Care', 'time': '15-25 min', 'imageUrl': 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Baby', 'label': 'Baby Care', 'time': '15-25 min', 'imageUrl': 'https://images.unsplash.com/photo-1519689680058-324335c77eba?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Meat', 'label': 'Meat & Fish', 'time': '20-30 min', 'imageUrl': 'https://images.unsplash.com/photo-1558030006-450675393462?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Sports', 'label': 'Sports &\nFitness', 'time': '40-50 min', 'imageUrl': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=90&w=400&h=400'},
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
              childAspectRatio: 0.65,
            ),
            itemCount: allCategories.length,
            itemBuilder: (context, index) {
              final cat = allCategories[index];
              final catId = cat['id'] as String;
              final isSelected = _selectedCategory == catId;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (catId == 'Gifts') {
                    setState(() {
                      _selectedNavIndex = 4;
                    });
                  } else if (catId == 'Food') {
                    setState(() {
                      _selectedNavIndex = 3;
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryScreen(
                          categoryId: catId,
                          categoryName: cat['label'] as String,
                        ),
                      ),
                    );
                  }
                },
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF0FDF4),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0C831F) : const Color(0xFFBBF7D0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: cat.containsKey('imageUrl')
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.network(
                                    cat['imageUrl'] as String,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(cat['icon'] as IconData, color: const Color(0xFF059669), size: 28),
                        ),
                        if ((cat['time'] as String).isNotEmpty)
                          Positioned(
                            bottom: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cat['time'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      cat['label'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? const Color(0xFF0C831F) : Colors.black87,
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
            itemCount: Provider.of<ShopProvider>(context).shops.length,
            itemBuilder: (context, index) {
              final shop = Provider.of<ShopProvider>(context).shops[index];
              return _buildShopCard(context, shop, Theme.of(context));
            },
          ),
        ],
      ),
    );
  }

  // ─── FOOD TAB ───
  Widget _buildFoodTab(BuildContext context) {
    final shops = Provider.of<ShopProvider>(context).shops;
    final cart = Provider.of<CartProvider>(context);

    // Extract all products from shops that belong to food-like categories
    List<MenuItem> foodProducts = [];
    Map<MenuItem, Shop> productToShopMap = {};
    for (var shop in shops) {
      for (var product in shop.menu) {
        if (product.category.toLowerCase() == 'food' || 
            product.category.toLowerCase().contains('burger') ||
            product.category.toLowerCase().contains('pizza') ||
            product.category.toLowerCase().contains('biryani') ||
            product.category.toLowerCase().contains('chinese') ||
            product.category.toLowerCase().contains('meal') ||
            shop.category.toLowerCase().contains('restaurant') ||
            shop.category.toLowerCase().contains('food')) {
          foodProducts.add(product);
          productToShopMap[product] = shop;
        }
      }
    }
    
    return Column(
      children: [
        // Custom Header for Food Tab
        Container(
          padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 12),
          color: Colors.white,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedNavIndex = 0; // Go back to Home tab
                  });
                },
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Food', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                    Row(
                      children: const [
                        Text('Delivering to: ', style: TextStyle(fontSize: 10, color: Colors.black54)),
                        Icon(Icons.location_on, size: 10, color: Color(0xFF0C831F)),
                        SizedBox(width: 2),
                        Flexible(
                          child: Text('Set your location', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 10, color: Color(0xFF0C831F), fontWeight: FontWeight.bold)),
                        ),
                        Icon(Icons.keyboard_arrow_down, size: 12, color: Color(0xFF0C831F)),
                      ],
                    ),
                  ],
                ),
              ),
              // 15 min pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.bolt, color: Color(0xFF059669), size: 16),
                    SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('15 min', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold, height: 1.0)),
                        Text('Delivery', style: TextStyle(color: Colors.black54, fontSize: 9, height: 1.0)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Cart Icon
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_cart_outlined, color: Colors.black87, size: 20),
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            cart.itemCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.black54),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Search for restaurants, cuisines or dishes...', style: TextStyle(color: Colors.black45, fontSize: 13)),
                  ),
                  const Icon(Icons.tune, color: Colors.black54),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Hero Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delicious Meals,\nDelivered Fast! ⚡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.2)),
                      const SizedBox(height: 8),
                      const Text('Your favorite food at your doorstep in 15 minutes.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C831F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Order Now', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network('https://images.unsplash.com/photo-1586190848861-99aa4a171e90?auto=format&fit=crop&q=90&w=200&h=200', width: 100, height: 100, fit: BoxFit.cover),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Food Categories
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCircularCategory('All', Icons.grid_view, isIcon: true, isSelected: true),
                _buildCircularCategory('Biryani', 'https://images.unsplash.com/photo-1633945274405-b6c8069047b0?auto=format&fit=crop&q=80&w=150&h=150'),
                _buildCircularCategory('Pizza', 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&q=80&w=150&h=150'),
                _buildCircularCategory('Burger', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&q=80&w=150&h=150'),
                _buildCircularCategory('Chinese', 'https://images.unsplash.com/photo-1552611052-33e04de081de?auto=format&fit=crop&q=80&w=150&h=150'),
                _buildCircularCategory('Thali', 'https://images.unsplash.com/photo-1626776876729-bab4369a5a5a?auto=format&fit=crop&q=80&w=150&h=150'),
                _buildCircularCategory('More', Icons.more_horiz, isIcon: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Top Picks for You
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Picks for You', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
              Row(
                children: const [
                  Text('See all', style: TextStyle(color: Color(0xFF0C831F), fontSize: 12, fontWeight: FontWeight.bold)),
                  Icon(Icons.arrow_forward, color: Color(0xFF0C831F), size: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (foodProducts.isNotEmpty)
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: foodProducts.length,
                itemBuilder: (context, index) {
                  final product = foodProducts[index];
                  final shop = productToShopMap[product]!;
                  return _buildTopPickCard(product, shop, cart);
                },
              ),
            ),
          const SizedBox(height: 24),
          
          // Popular Cuisines
          const Text('Popular Cuisines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCuisineCard('North Indian', 'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?auto=format&fit=crop&q=80&w=200&h=150'),
                _buildCuisineCard('South Indian', 'https://images.unsplash.com/photo-1625220194771-7ebdea0b70b9?auto=format&fit=crop&q=80&w=200&h=150'),
                _buildCuisineCard('Street Food', 'https://images.unsplash.com/photo-1606491956689-2ea866880c84?auto=format&fit=crop&q=80&w=200&h=150'),
                _buildCuisineCard('Desserts', 'https://images.unsplash.com/photo-1551024506-0bccd828d307?auto=format&fit=crop&q=80&w=200&h=150'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Offers for You
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Offers for You', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
              Row(
                children: const [
                  Text('See all', style: TextStyle(color: Color(0xFF0C831F), fontSize: 12, fontWeight: FontWeight.bold)),
                  Icon(Icons.arrow_forward, color: Color(0xFF0C831F), size: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildOfferBanner('FLAT 20% OFF', 'Up to ₹100', 'On orders above ₹199', 'NOLATE20', const Color(0xFFE8F5E9), 'https://images.unsplash.com/photo-1585032226651-759b368d7246?auto=format&fit=crop&q=80&w=150&h=150'),
                _buildOfferBanner('FLAT ₹50 OFF', 'On orders above ₹249', '', 'NOLATE50', const Color(0xFFFCE4EC), 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&q=80&w=150&h=150'),
                _buildOfferBanner('FREE DELIVERY', 'On orders above ₹99', '', 'NOLATEFREE', const Color(0xFFFFF3E0), 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&q=80&w=150&h=150'),
              ],
            ),
          ),
          const SizedBox(height: 60), // padding for cart pill
        ],
      ),
    ),
    ),
    ],
    );
  }

  Widget _buildCircularCategory(String title, dynamic iconOrImage, {bool isIcon = false, bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0C831F) : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isIcon
                ? Icon(iconOrImage as IconData, color: isSelected ? Colors.white : Colors.black87, size: 28)
                : ClipOval(child: Image.network(iconOrImage as String, width: 60, height: 60, fit: BoxFit.cover)),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTopPickCard(MenuItem product, Shop shop, CartProvider cart) {
    return GestureDetector(
      onTap: () {
        cart.addItem(product, shop);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(product.imageUrl, height: 110, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF0C831F), borderRadius: BorderRadius.circular(4)),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt, color: Colors.white, size: 10),
                        Text('15 min', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<WishlistProvider>(
                    builder: (context, wishlist, child) {
                      final isLiked = wishlist.isWishlisted(product.id);
                      return GestureDetector(
                        onTap: () {
                          wishlist.toggleWishlist(product, shop);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.black54,
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 12),
                      const SizedBox(width: 4),
                      Text('4.${(product.name.length % 5) + 1} (${product.price.toInt()}+)', style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${product.category} • ₹₹', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.black45)),
                  const SizedBox(height: 8),
                  Text('₹${product.price.toInt()} for one', style: const TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuisineCard(String title, String imageUrl) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipOval(child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildOfferBanner(String title, String subtitle1, String subtitle2, String code, Color bgColor, String imageUrl) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 4),
                if (subtitle1.isNotEmpty) Text(subtitle1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                if (subtitle2.isNotEmpty) Text(subtitle2, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  child: Text(code, style: const TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  // ─── GIFT TAB ───
  Widget _buildGiftTab(BuildContext context) {
    final shops = Provider.of<ShopProvider>(context).shops;
    final cart = Provider.of<CartProvider>(context);

    List<MenuItem> giftProducts = [];
    Map<MenuItem, Shop> productToShopMap = {};
    for (var shop in shops) {
      if (shop.category.toLowerCase().contains('gift') || 
          shop.name.toLowerCase().contains('gift')) {
        for (var product in shop.menu) {
          giftProducts.add(product);
          productToShopMap[product] = shop;
        }
      }
    }
    
    final popularGifts = giftProducts.take(4).toList();
    final hampers = giftProducts.skip(4).take(4).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 12),
          color: Colors.white,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedNavIndex = 0;
                  });
                },
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gifts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                    Row(
                      children: const [
                        Text('Delivering to: ', style: TextStyle(fontSize: 10, color: Colors.black54)),
                        Icon(Icons.location_on, size: 10, color: Color(0xFF0C831F)),
                        SizedBox(width: 2),
                        Flexible(
                          child: Text('Set your location', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 10, color: Color(0xFF0C831F), fontWeight: FontWeight.bold)),
                        ),
                        Icon(Icons.keyboard_arrow_down, size: 12, color: Color(0xFF0C831F)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.bolt, color: Color(0xFF059669), size: 16),
                    SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('15 min', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold, height: 1.0)),
                        Text('Delivery', style: TextStyle(color: Colors.black54, fontSize: 9, height: 1.0)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_cart_outlined, color: Colors.black87, size: 20),
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            cart.itemCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SearchScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: Colors.black54, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search for gifts, hampers, flowers...',
                            style: TextStyle(color: Colors.black38, fontSize: 14),
                          ),
                        ),
                        Icon(Icons.tune, color: Colors.black54, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE4E1), Color(0xFFFFF0F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Make Every Moment\nExtra Special 🎁', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.2)),
                            const SizedBox(height: 8),
                            const Text('Send love, smiles & surprises\nin just 15 minutes!', style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.3)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B0021),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text('Send a Gift', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Image.network(
                          'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?auto=format&fit=crop&q=90&w=300&h=300',
                          fit: BoxFit.contain,
                          height: 100,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildGiftCircularCategory('All', Icons.grid_view, isIcon: true, isSelected: true),
                      _buildGiftCircularCategory('Flowers', 'https://images.unsplash.com/photo-1563241527-3004b7be0ffd?auto=format&fit=crop&q=80&w=150&h=150'),
                      _buildGiftCircularCategory('Cakes', 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&q=80&w=150&h=150'),
                      _buildGiftCircularCategory('Chocolates', 'https://images.unsplash.com/photo-1548907040-4baa42d10919?auto=format&fit=crop&q=80&w=150&h=150'),
                      _buildGiftCircularCategory('Teddy Bears', 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&q=80&w=150&h=150'),
                      _buildGiftCircularCategory('Hampers', 'https://images.unsplash.com/photo-1513201099705-a9746e1e201f?auto=format&fit=crop&q=80&w=150&h=150'),
                      _buildGiftCircularCategory('More', Icons.more_horiz, isIcon: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Popular Gifts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
                    Row(
                      children: const [
                        Text('See all', style: TextStyle(color: Color(0xFF8B0021), fontSize: 12, fontWeight: FontWeight.bold)),
                        Icon(Icons.arrow_forward, color: Color(0xFF8B0021), size: 14),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (popularGifts.isNotEmpty)
                  SizedBox(
                    height: 230,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: popularGifts.length,
                      itemBuilder: (context, index) {
                        final product = popularGifts[index];
                        final shop = productToShopMap[product]!;
                        return _buildGiftPickCard(product, shop, cart);
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Gift Hampers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
                    Row(
                      children: const [
                        Text('See all', style: TextStyle(color: Color(0xFF8B0021), fontSize: 12, fontWeight: FontWeight.bold)),
                        Icon(Icons.arrow_forward, color: Color(0xFF8B0021), size: 14),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (hampers.isNotEmpty)
                  SizedBox(
                    height: 230,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: hampers.length,
                      itemBuilder: (context, index) {
                        final product = hampers[index];
                        final shop = productToShopMap[product]!;
                        return _buildGiftPickCard(product, shop, cart);
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFeatureItem(Icons.bolt, '15 min\nDelivery', const Color(0xFF8B0021)),
                      _buildFeatureItem(Icons.local_florist, 'Fresh &\nPremium', const Color(0xFF8B0021)),
                      _buildFeatureItem(Icons.card_giftcard, 'Beautifully\nPacked', const Color(0xFF8B0021)),
                      _buildFeatureItem(Icons.shield_outlined, 'Safe\nDelivery', const Color(0xFF8B0021)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGiftCircularCategory(String title, dynamic iconOrImage, {bool isIcon = false, bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF8B0021) : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isIcon
                ? Icon(iconOrImage as IconData, color: isSelected ? Colors.white : const Color(0xFF8B0021), size: 28)
                : ClipOval(child: Image.network(iconOrImage as String, width: 60, height: 60, fit: BoxFit.cover)),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2)),
      ],
    );
  }

  Widget _buildGiftPickCard(MenuItem product, Shop shop, CartProvider cart) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(product.imageUrl, height: 120, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: const [
                        Icon(Icons.bolt, color: Color(0xFF8B0021), size: 10),
                        Text('15-20 min', style: TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<WishlistProvider>(
                    builder: (context, wishlist, child) {
                      final isLiked = wishlist.isWishlisted(product.id);
                      return GestureDetector(
                        onTap: () {
                          wishlist.toggleWishlist(product, shop);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.black54,
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(product.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 12),
                      const SizedBox(width: 4),
                      Text('4.${(product.name.length % 5) + 1} (${product.price.toInt()}+)', style: const TextStyle(fontSize: 9, color: Colors.black87, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${product.price.toInt()}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 13)),
                      GestureDetector(
                        onTap: () {
                          cart.addItem(product, shop);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B0021),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('ADD', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
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

  Widget _buildZoodoHeader(BuildContext context, AppUser user, AuthProvider auth) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(bottom: 12, top: 12, left: 14, right: 14),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Expanded(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/logo.jpg',
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'NOLATE',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF059669),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Everything you need!',
                              style: GoogleFonts.outfit(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Right side icons
              Row(
                children: [
                  // 15 min delivery pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: Color(0xFF059669), size: 16),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '15 min',
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              'Delivery',
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 9),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Wallet representation
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ZoodoMoneyScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF059669), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '₹0',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Notification bell
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                      setState(() {}); // Refresh badge on return
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                          ),
                          child: Icon(Icons.notifications_outlined, color: isDark ? Colors.white : Colors.black87, size: 20),
                        ),
                        if (NotificationScreen.unreadCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${NotificationScreen.unreadCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Profile icon that opens screen
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                    child: Builder(builder: (context) {
                      final supaUser = Supabase.instance.client.auth.currentUser;
                      final avatarUrl = supaUser?.userMetadata?['avatar_url'] as String?;
                      final fullName = supaUser?.userMetadata?['full_name'] as String? ?? supaUser?.userMetadata?['name'] as String? ?? '';
                      final initials = fullName.isNotEmpty
                          ? fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                          : null;

                      if (avatarUrl != null && avatarUrl.isNotEmpty) {
                        return CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(avatarUrl),
                          backgroundColor: const Color(0xFFE0E0E0),
                        );
                      } else if (initials != null) {
                        return CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF1A1A2E),
                          child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        );
                      } else {
                        return const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFF1A1A2E),
                          child: Icon(Icons.person, color: Colors.white, size: 18),
                        );
                      }
                    }),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Location Row
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => LocationPickerSheet(
                  currentAddress: _currentAddress ?? user.address,
                  onLocationSelected: (address, coord) {
                    setState(() {
                      _currentAddress = address;
                    });
                    auth.updateCurrentUserLocation(coord, address);
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9), // Very light grey
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF059669), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        const Text(
                          'Deliver to: ',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        Expanded(
                          child: Text(
                            _currentAddress ?? user.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black87, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '850 m away',
                    style: TextStyle(color: Colors.black45, fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Text(
                      'Change',
                      style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: const [
                  SizedBox(width: 16),
                  Icon(Icons.search, color: Colors.black45, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Search "milk", "bread", "cake", "gift" or shops...',
                      style: TextStyle(color: Colors.black38, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.mic_none_outlined, color: Colors.black45, size: 22),
                  SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ],
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
              child: const Text('Clear & Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      {'id': 'Grocery', 'label': 'Grocery', 'time': '10-20 min', 'imageUrl': 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Fruits', 'label': 'Fruits &\nVegetables', 'time': '10-20 min', 'imageUrl': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Cakes', 'label': 'Cakes', 'time': '30 min', 'imageUrl': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Gifts', 'label': 'Gifts', 'time': '30 min', 'imageUrl': 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Flowers', 'label': 'Flowers', 'time': '15-20 min', 'imageUrl': 'https://images.unsplash.com/photo-1563241527-3004b7be0ffd?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Dairy', 'label': 'Dairy &\nBreakfast', 'time': '10-20 min', 'imageUrl': 'https://images.unsplash.com/photo-1628088062854-d1870b4553da?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Snacks', 'label': 'Snacks &\nBeverages', 'time': '10-20 min', 'imageUrl': 'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Food', 'label': 'Food', 'time': '20-30 min', 'imageUrl': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'Medicines', 'label': 'Medicines', 'time': '15-25 min', 'imageUrl': 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?auto=format&fit=crop&q=90&w=400&h=400'},
      {'id': 'More', 'label': 'More\nCategories', 'time': '', 'icon': Icons.grid_view},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shop by Category',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedNavIndex = 2;
                  });
                },
                child: Row(
                  children: const [
                    Text('See All', style: TextStyle(color: Color(0xFF059669), fontSize: 13, fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, color: Color(0xFF059669), size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 0.6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return GestureDetector(
                onTap: () {
                  if (cat['id'] == 'More') {
                    setState(() {
                      _selectedNavIndex = 2;
                    });
                  } else if (cat['id'] == 'Gifts') {
                    setState(() {
                      _selectedNavIndex = 4;
                    });
                  } else if (cat['id'] == 'Food') {
                    setState(() {
                      _selectedNavIndex = 3;
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryScreen(
                          categoryId: cat['id'] as String,
                          categoryName: cat['label'] as String,
                        ),
                      ),
                    );
                  }
                },
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF0FDF4),
                            border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
                          ),
                          child: cat.containsKey('imageUrl')
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.network(
                                    cat['imageUrl'] as String,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(cat['icon'] as IconData, color: const Color(0xFF059669), size: 28),
                        ),
                        if ((cat['time'] as String).isNotEmpty)
                          Positioned(
                            bottom: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cat['time'] as String,
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      cat['label'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrustMarkers() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTrustItem(Icons.bolt, '10-30 min\nDelivery', iconSize: 24),
          Container(width: 1, height: 24, color: Colors.black12),
          _buildTrustItem(Icons.verified_user_rounded, 'Best\nQuality', iconSize: 24),
          Container(width: 1, height: 24, color: Colors.black12),
          _buildTrustItem(Icons.inventory_2, 'Fresh\nProducts', iconSize: 24),
          Container(width: 1, height: 24, color: Colors.black12),
          _buildTrustItem(Icons.lock_outline, 'Safe\nPackaging', iconSize: 24),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String label, {double iconSize = 20}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF059669), size: iconSize),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w700, height: 1.2),
        ),
      ],
    );
  }

  Widget _buildEpicSaleCarousel() {
    return Consumer<BannerProvider>(
      builder: (context, bannerProvider, child) {
        if (bannerProvider.isLoading) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final banners = bannerProvider.banners;
        if (banners.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              SizedBox(
                height: 160,
                child: PageView.builder(
                  itemCount: banners.length,
                  onPageChanged: (index) {
                    setState(() {
                      _activeCarouselIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final banner = banners[index];
                    return GestureDetector(
                      onTap: () {
                        // Handle banner action based on action_type
                        if (banner.actionType == 'Open Category') {
                          setState(() {
                            _selectedCategory = banner.categoryId ?? 'All';
                          });
                        } else if (banner.actionType == 'Open Shop' && banner.shopId != null) {
                          final shopProvider = Provider.of<ShopProvider>(context, listen: false);
                          try {
                            final shop = shopProvider.shops.firstWhere((s) => s.id == banner.shopId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ShopDetailsScreen(shop: shop)),
                            );
                          } catch (e) {
                            debugPrint('Shop not found');
                          }
                        } else if (banner.actionType == 'Open Product' && banner.productId != null) {
                          final shopProvider = Provider.of<ShopProvider>(context, listen: false);
                          for (var shop in shopProvider.shops) {
                            for (var product in shop.menu) {
                              if (product.id == banner.productId) {
                                // We found the product, but ShopDetailsScreen requires a Shop.
                                // We could open a generic Product Details sheet/screen here.
                                // For now, let's navigate to the shop containing the product.
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ShopDetailsScreen(shop: shop)),
                                );
                                return;
                              }
                            }
                          }
                        } else if (banner.actionType == 'External Link' && banner.externalLink != null) {
                          // Could launch URL here if url_launcher was added
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Dot indicator
              if (banners.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(banners.length, (index) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _activeCarouselIndex
                            ? const Color(0xFF1E3A8A)
                            : Colors.black26,
                      ),
                    );
                  }),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHotDealsCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          child: Text(
            "Today's Hot Deals",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            children: [
              _buildHotDealCard(
                title: 'Gifts for Every\nOccasion',
                subtitle: 'Up to 40% Off',
                colors: [const Color(0xFFFFE4E6), const Color(0xFFFECDD3)],
                textColor: Colors.black87,
                imageUrl: 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?auto=format&fit=crop&w=150',
              ),
              const SizedBox(width: 12),
              _buildHotDealCard(
                title: 'Fresh Fruits',
                subtitle: 'Flat 20% Off',
                colors: [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0)],
                textColor: Colors.black87,
                imageUrl: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=150',
              ),
              const SizedBox(width: 12),
              _buildHotDealCard(
                title: 'Snacks Combo',
                subtitle: 'Buy 2 Get 1',
                colors: [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                textColor: Colors.black87,
                imageUrl: 'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?auto=format&fit=crop&w=150',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHotDealCard({
    required String title,
    required String subtitle,
    required List<Color> colors,
    required Color textColor,
    required String imageUrl,
  }) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
              child: Image.network(imageUrl, width: 120, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    title,
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w900, height: 1.2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, MenuItem product, Shop shop, CartProvider cart) {
    final cartItem = cart.items[product.id];
    final quantity = cartItem?.quantity ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product, shop: shop),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Hero(
                      tag: 'product_${product.id}',
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Icon(Icons.fastfood_rounded, size: 40, color: Colors.black12),
                            )
                          : const Icon(Icons.fastfood_rounded, size: 40, color: Colors.black12),
                    ),
                  ),
                ),
                // Favorite icon
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<WishlistProvider>(
                    builder: (context, wishlist, child) {
                      final isLiked = wishlist.isWishlisted(product.id);
                      return GestureDetector(
                        onTap: () {
                          wishlist.toggleWishlist(product, shop);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isLiked ? Colors.red : Colors.black54,
                          ),
                        ),
                      );
                    }
                  ),
                ),
                // Time badge
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_filled_rounded, size: 10, color: Color(0xFF166534)),
                        const SizedBox(width: 2),
                        Text(
                          '${shop.deliveryTimeMinutes} MINS',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
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
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.category,
                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '₹${product.price.toInt()}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black87),
                        ),
                        // Add Button
                        Container(
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFF166534),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: quantity > 0
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => cart.removeSingleItem(product.id),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(Icons.remove, size: 14, color: Colors.white),
                                      ),
                                    ),
                                    Text(
                                      '$quantity',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        final added = cart.addItem(product, shop);
                                        if (!added) {
                                          _showDifferentShopDialog(context, cart, product, shop);
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(Icons.add, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                )
                              : InkWell(
                                  onTap: () {
                                    final added = cart.addItem(product, shop);
                                    if (!added) {
                                      _showDifferentShopDialog(context, cart, product, shop);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                    child: Center(
                                      child: Text(
                                        'ADD',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
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
              child: shop.imageUrl.isNotEmpty
                  ? Image.network(
                      shop.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[100],
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF3F0FF),
                        child: const Icon(Icons.storefront_rounded, size: 48, color: Color(0xFF9B8FD0)),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF3F0FF),
                      child: const Icon(Icons.storefront_rounded, size: 48, color: Color(0xFF9B8FD0)),
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
                          color: const Color(0xFFF3F0FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBDB0F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFF6B35), size: 12),
                            const SizedBox(width: 2),
                            Text(
                              shop.rating.toString(),
                              style: const TextStyle(
                                color: Color(0xFF059669),
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
    final List<MapEntry<Shop, MenuItem>> featuredItems = [];
    final shops = Provider.of<ShopProvider>(context).shops;
    for (var shop in shops) {
      for (var item in shop.menu) {
        if (featuredItems.length < 8) {
          featuredItems.add(MapEntry(shop, item));
        }
      }
    }

    return Container(
      color: const Color(0xFFF3F4F6),
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
                  child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF059669), size: 14),
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
                      color: isAdded ? const Color(0xFF059669) : Colors.black.withValues(alpha: 0.05),
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
                                        border: Border.all(color: const Color(0xFF059669), width: 1.0),
                                      ),
                                      child: const Text(
                                        'ADD',
                                        style: TextStyle(
                                          color: Color(0xFF059669),
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
                                      color: const Color(0xFF059669),
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
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isActive: _selectedNavIndex == 0,
            activeColor: const Color(0xFF059669),
            onTap: () => setState(() => _selectedNavIndex = 0),
          ),
          _buildBottomNavItem(
            icon: Icons.history_rounded,
            label: 'Orders',
            isActive: _selectedNavIndex == 1,
            activeColor: const Color(0xFF059669),
            onTap: () => setState(() => _selectedNavIndex = 1),
          ),
          _buildBottomNavItem(
            icon: Icons.grid_view_rounded,
            label: 'Categories',
            isActive: _selectedNavIndex == 2,
            activeColor: const Color(0xFF059669),
            onTap: () => setState(() => _selectedNavIndex = 2),
          ),
          _buildBottomNavItem(
            icon: Icons.restaurant_rounded,
            label: 'Food',
            isActive: _selectedNavIndex == 3,
            activeColor: const Color(0xFF059669),
            onTap: () => setState(() => _selectedNavIndex = 3),
          ),
          _buildBottomNavItem(
            icon: Icons.card_giftcard_rounded,
            label: 'Gifts',
            isActive: _selectedNavIndex == 4,
            activeColor: const Color(0xFF059669),
            onTap: () => setState(() => _selectedNavIndex = 4),
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
    final color = isActive ? (activeColor ?? const Color(0xFF059669)) : Colors.black38;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 65,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
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


