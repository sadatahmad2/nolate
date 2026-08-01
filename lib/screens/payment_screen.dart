import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../models/models.dart';
import 'tracking_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'upi';
  String _selectedUpiApp = 'gpay';
  bool _isProcessing = false;
  bool _showSuccess = false;

  void _processPayment() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final order = Provider.of<OrderProvider>(context, listen: false);

    if (cart.currentShop == null) return;

    // Use Supabase user (works for both Google and manual login)
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Build AppUser from available source
    AppUser? appUser = auth.currentUser;
    if (appUser == null && supabaseUser != null) {
      appUser = AppUser(
        name: supabaseUser.userMetadata?['full_name'] ?? supabaseUser.email ?? 'Customer',
        email: supabaseUser.email ?? '',
        mobile: '',
        password: '',
        address: 'Default Address',
        location: const Coordinate(0.5, 0.5),
      );
    }

    if (appUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to place an order')),
      );
      return;
    }

    setState(() { _isProcessing = true; });

    await Future.delayed(const Duration(seconds: 2));

    await order.placeOrder(
      shop: cart.currentShop!,
      items: cart.itemsList,
      totalAmount: cart.totalAmount,
      deliveryFee: cart.actualDeliveryFee,
      tax: cart.platformFee,
      user: appUser,
    );

    setState(() {
      _isProcessing = false;
      _showSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    if (_isProcessing) {
      return _buildProcessingOverlay(theme);
    }

    if (_showSuccess) {
      return _buildSuccessScreen(theme);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F4), // Light background
      appBar: AppBar(
        title: const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount Summary card
                    _buildAmountSummaryCard(cart, theme),
                    const SizedBox(height: 20),

                    const Text(
                      'Select Payment Method',
                      style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // Payment options
                    _buildPaymentMethodTile(
                      id: 'upi',
                      title: 'UPI (Pay via Google Pay / PhonePe)',
                      subtitle: 'Instant secure payment via UPI app',
                      icon: Icons.qr_code_scanner_rounded,
                      theme: theme,
                    ),
                    if (_selectedMethod == 'upi') ...[
                      const SizedBox(height: 8),
                      _buildUpiAppsSelection(theme),
                    ],
                    const SizedBox(height: 10),

                    _buildPaymentMethodTile(
                      id: 'card',
                      title: 'Credit / Debit Cards',
                      subtitle: 'Visa, Mastercard, RuPay, Maestro',
                      icon: Icons.credit_card_rounded,
                      theme: theme,
                    ),
                    const SizedBox(height: 10),

                    _buildPaymentMethodTile(
                      id: 'cod',
                      title: 'Cash on Delivery (COD)',
                      subtitle: 'Pay with cash/digital options at door',
                      icon: Icons.payments_outlined,
                      theme: theme,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            _buildPayButton(cart, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSummaryCard(CartProvider cart, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.15)), // Deep Indigo border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL AMOUNT DUE', 
                style: TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${cart.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFF059669), fontSize: 22, fontWeight: FontWeight.w800), // Deep Indigo
              ),
            ],
          ),
          const Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 28), // Deep Indigo shield
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeData theme,
  }) {
    final isSelected = _selectedMethod == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : Colors.black.withValues(alpha: 0.04), // Deep Indigo selection
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF059669) : Colors.black38,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF059669) : Colors.black26,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF059669),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpiAppsSelection(ThemeData theme) {
    final upiApps = [
      {'id': 'gpay', 'name': 'Google Pay'},
      {'id': 'phonepe', 'name': 'PhonePe'},
      {'id': 'paytm', 'name': 'Paytm'},
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 14.0),
      child: Row(
        children: upiApps.map((app) {
          final isSelected = _selectedUpiApp == app['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(app['name']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedUpiApp = app['id']!;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF059669),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.black12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPayButton(CartProvider cart, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: ElevatedButton(
        onPressed: _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Center(
          child: Text(
            _selectedMethod == 'cod' ? 'Place Order' : 'Pay ₹${cart.grandTotal.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay(ThemeData theme) {
    return Scaffold(
      backgroundColor: Colors.white, // Light background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)), // Deep Indigo
                strokeWidth: 4,
              ),
              const SizedBox(height: 24),
              const Text(
                'Securing Connection...',
                style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Communicating with banking servers. Please do not press back or refresh.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 54),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Order Placed Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'Thank you! Your payment was secure and the merchant has been notified of your order details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const TrackingScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Track Your Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
