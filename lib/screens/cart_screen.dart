import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import 'payment_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F4), // Light background
      appBar: AppBar(
        title: const Text(
          'Checkout', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: cart.itemCount == 0
          ? _buildEmptyCart(context, theme)
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (cart.currentShop != null) ...[
                            Text(
                              'Ordering from ${cart.currentShop!.name}',
                              style: const TextStyle(
                                color: Color(0xFF0C831F), // Zoodo Green
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          
                          // Cart items list card
                          _buildCartItemsCard(cart, theme),
                          const SizedBox(height: 16),

                          // Delivery details card
                          if (user != null) _buildDeliveryDetailsCard(user, cart.currentShop, theme),
                          const SizedBox(height: 16),

                          // Price details card
                          _buildPriceDetailsCard(cart, theme),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),

                  // Bottom checkout button
                  _buildPaymentButton(context, cart, theme),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 70, color: Colors.black12),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add some products to place an order!',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C831F), // Zoodo Green
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Browse Shops', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsCard(CartProvider cart, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: cart.itemsList.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.black12, height: 20),
            itemBuilder: (context, index) {
              final cartItem = cart.itemsList[index];
              return Row(
                children: [
                  // Image Thumbnail Left
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      cartItem.item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.fastfood, color: Colors.black26),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cartItem.item.name,
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '₹${cartItem.item.price.toStringAsFixed(2)} each',
                          style: const TextStyle(color: Colors.black45, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Quantitative Controller (Zoodo style: Green/White border pill)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0C831F), width: 1.0),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.remove, size: 12, color: Color(0xFF0C831F)),
                          onPressed: () => cart.removeSingleItem(cartItem.item.id),
                        ),
                        Text(
                          cartItem.quantity.toString(),
                          style: const TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.add, size: 12, color: Color(0xFF0C831F)),
                          onPressed: () => cart.addItem(cartItem.item, cart.currentShop!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '₹${cartItem.total.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDetailsCard(AppUser user, Shop? shop, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_bike_rounded, color: Color(0xFF0C831F), size: 18),
              SizedBox(width: 8),
              Text(
                'Delivery Address',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            user.address,
            style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
          ),
          if (shop != null) ...[
            const Divider(color: Colors.black12, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Distance to shop',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
                Text(
                  '${shop.distanceKm} km',
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Delivery Time',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
                Text(
                  '${shop.deliveryTimeMinutes} mins',
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildPriceDetailsCard(CartProvider cart, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Details',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildBillRow('Items Total', '₹${cart.totalAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _buildBillRow('Delivery Fee (Distance base)', '₹${cart.deliveryFee.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _buildBillRow('Taxes & GST (5%)', '₹${cart.tax.toStringAsFixed(2)}'),
          const Divider(color: Colors.black12, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 15),
              ),
              Text(
                '₹${cart.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black45, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPaymentButton(BuildContext context, CartProvider cart, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PaymentScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0C831F), // Zoodo Green
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: const Center(
          child: Text(
            'Choose address at next step',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
