import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import 'package:provider/provider.dart';
import 'zoodo_money_screen.dart';
import 'tracking_screen.dart';
import 'location_picker_sheet.dart';
import 'splash_screen.dart';
import 'wishlist_screen.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import 'placeholder_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF059669), // Deep Indigo
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1060), Color(0xFF059669), Color(0xFFF3F0FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Builder(builder: (context) {
                      final supaUser = Supabase.instance.client.auth.currentUser;
                      final avatarUrl = supaUser?.userMetadata?['avatar_url'] as String?;
                      final fullName = supaUser?.userMetadata?['full_name'] as String? ?? supaUser?.userMetadata?['name'] as String? ?? user?.name ?? 'Guest User';
                      final initials = fullName != 'Guest User' && fullName.isNotEmpty
                          ? fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                          : null;
                      final email = supaUser?.email ?? '';

                      return Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              image: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(avatarUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? (initials != null
                                    ? Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)))
                                    : const Icon(Icons.person, size: 50, color: Colors.white))
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email.isNotEmpty ? email : (user != null ? '+91 ${user.mobile}' : 'Register to get full access'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Add your birthday banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _showComingSoon(context, 'Birthday rewards'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add your birthday',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text(
                                    'Enter details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFFFF6B35), // Warm Coral
                                    ),
                                  ),
                                  Icon(Icons.arrow_right, color: const Color(0xFFFF6B35), size: 18),
                                ],
                              ),
                            ],
                          ),
                          const Icon(Icons.cake, color: Color(0xFFFF6B35), size: 40),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Three cards row
                  Row(
                    children: [
                      _buildTopCard(
                        icon: Icons.shopping_basket_outlined,
                        title: 'Your orders',
                        onTap: () {
                          final activeOrder = Provider.of<OrderProvider>(context, listen: false).activeOrder;
                          if (activeOrder != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const TrackingScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You have no active orders. Place an order to track!'),
                                backgroundColor: Color(0xFF059669),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildTopCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Nolate Money',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const ZoodoMoneyScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildTopCard(
                        icon: Icons.support_agent_outlined,
                        title: 'Need help?',
                        onTap: () {
                          _showComingSoon(context, 'Customer Support Chat');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Appearance
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wb_sunny_outlined, color: Theme.of(context).textTheme.bodyLarge?.color),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Appearance',
                            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                        ),
                        DropdownButton<String>(
                          value: Provider.of<ThemeProvider>(context).themeModeString,
                          underline: const SizedBox(),
                          icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).primaryColor),
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              Provider.of<ThemeProvider>(context, listen: false).setThemeMode(newValue);
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'LIGHT', child: Text('LIGHT')),
                            DropdownMenuItem(value: 'DARK', child: Text('DARK')),
                            DropdownMenuItem(value: 'SYSTEM', child: Text('SYSTEM')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sensitive items toggle
                  Consumer<SettingsProvider>(
                    builder: (context, settings, _) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.visibility_off_outlined, color: Theme.of(context).primaryColor, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hide sensitive items',
                                    style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sexual wellness, nicotine products and other sensitive items will be hidden',
                                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Know more',
                                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: settings.hideSensitiveItems,
                              onChanged: (val) {
                                settings.toggleSensitiveItems(val);
                              },
                              activeThumbColor: Theme.of(context).colorScheme.secondary,
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 24),

                  // Your Information Section
                  Text(
                    'Your information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(Icons.menu_book_outlined, 'Address book', onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => LocationPickerSheet(
                              currentAddress: user?.address ?? '',
                              onLocationSelected: (address, coord) {
                                Provider.of<AuthProvider>(context, listen: false)
                                    .updateCurrentUserLocation(coord, address);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Address updated: $address'),
                                    backgroundColor: const Color(0xFF059669),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.receipt_long_outlined, 'Bookmarked recipes', onTap: () {
                          _showComingSoon(context, 'Bookmarked Recipes');
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.favorite_border, 'Your wishlist', onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WishlistScreen()),
                          );
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.description_outlined, 'GST details', onTap: () {
                          _showComingSoon(context, 'GST details');
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.card_giftcard_outlined, 'E-gift cards', onTap: () {
                          _showComingSoon(context, 'E-gift cards');
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.medical_services_outlined, 'Your prescriptions', isLast: true, onTap: () {
                          _showUploadPrescriptionDialog(context);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment and coupons Section
                  Text(
                    'Payment and coupons',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(Icons.account_balance_wallet_outlined, 'Nolate Money', onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const ZoodoMoneyScreen()),
                          );
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.credit_card_outlined, 'Payment settings', onTap: () {
                          _showComingSoon(context, 'Payment Settings');
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.card_giftcard_outlined, 'Claim Gift card', onTap: () {
                          _showClaimGiftCardDialog(context);
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.redeem_outlined, 'Your collected rewards', isLast: true, onTap: () {
                          _showComingSoon(context, 'Rewards');
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Feeding India Section
                  Text(
                    'Feeding India',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(Icons.volunteer_activism_outlined, 'Your impact', onTap: () {
                          _showComingSoon(context, 'Feeding India Impact');
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.receipt_outlined, 'Get donation receipt', isLast: true, onTap: () {
                          _showComingSoon(context, 'Donation Receipt');
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Other Information Section
                  Text(
                    'Other Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(Icons.share_outlined, 'Share the app', onTap: () {
                          _showShareDialog(context);
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.info_outline, 'About us', onTap: () {
                          _showAboutUsDialog(context);
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.storefront_outlined, 'Sell on Nolate', onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: const Text('Independent Merchant App', style: TextStyle(fontWeight: FontWeight.bold)),
                              content: const Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Merchant Mode is now a completely separate Flutter application!',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Please launch and run the "merchant_app" project to manage your stores, list products, and accept orders. Your updates will sync here automatically!',
                                    style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Got it!', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.lock_outline, 'Account privacy', onTap: () {
                          _showComingSoon(context, 'Privacy settings');
                        }),
                        _buildDivider(),
                        _buildListTile(Icons.notifications_none_outlined, 'Notification preferences', onTap: () {
                          _showComingSoon(context, 'Notification settings');
                        }),
                        _buildDivider(),
                        _buildListTile(
                          Icons.logout_outlined,
                          'Log out',
                          isLast: true,
                          onTap: () async {
                            Provider.of<AuthProvider>(context, listen: false).logout();
                            await Supabase.instance.client.auth.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const SplashScreen()),
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCard({required IconData icon, required String title, required VoidCallback onTap}) {
    return Builder(builder: (context) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Theme.of(context).primaryColor, size: 28),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildListTile(IconData icon, String title, {bool isLast = false, required VoidCallback onTap}) {
    return Builder(builder: (context) {
      return ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
        title: Text(title, style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        shape: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 0.5)),
      );
    });
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Colors.transparent);
  }

  void _showComingSoon(BuildContext context, String feature) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaceholderScreen(
          title: feature,
          icon: Icons.auto_awesome,
          description: 'This feature is currently being built and will be available soon!',
        ),
      ),
    );
  }

  void _showUploadPrescriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Upload Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please upload a valid doctor prescription to order prescription medicines.', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prescription uploaded from Camera!')));
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prescription uploaded from Gallery!')));
                    },
                    icon: const Icon(Icons.photo),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                  ),
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.black45)),
            )
          ],
        );
      },
    );
  }

  void _showClaimGiftCardDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Claim Gift Card', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your 16-digit gift card code to add balance to your Nolate Money wallet.', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLength: 16,
                decoration: InputDecoration(
                  hintText: 'ABCD-EFGH-IJKL-MNOP',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.black45)),
            ),
            ElevatedButton(
              onPressed: () {
                final code = controller.text.trim();
                Navigator.pop(context);
                if (code.length == 16) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gift card of ₹500 claimed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid gift card code!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
              child: const Text('Claim'),
            ),
          ],
        );
      },
    );
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Share Nolate App', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.share_rounded, size: 50, color: Color(0xFFFF6B35)),
              const SizedBox(height: 16),
              const Text('Spread the word! Share Nolate with your friends and family and get ₹50 cashback on their first order.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.link, color: Color(0xFF059669)),
                    SizedBox(width: 10),
                    Expanded(child: Text('https://nolate.app/refer/nolate50', style: TextStyle(fontSize: 12, color: Color(0xFF059669)))),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.black45)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
              child: const Text('Copy Link'),
            )
          ],
        );
      },
    );
  }

  void _showAboutUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('About Nolate', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0 (Nolate Midnight Purple & Coral Upgrade)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(height: 10),
            Text('Nolate is a next-generation hyper-local instant delivery app designed to deliver fresh food, groceries, custom gifts, sweets, and daily essentials to your doorstep within 10-15 minutes.', style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4)),
            SizedBox(height: 10),
            Text('Developed with passion for fast, secure, and beautiful user experience.', style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.black45)),
          ),
        ],
      ),
    );
  }
}
