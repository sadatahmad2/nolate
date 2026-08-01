import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/models.dart';
import 'home_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final theme = Theme.of(context);
    final order = orderProvider.activeOrder;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F4),
      appBar: AppBar(
        title: const Text('Live Tracking', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        actions: [
          if (order != null)
            TextButton(
              onPressed: () {
                _showOrderDetailsDialog(context, order);
              },
              child: const Text('Items', style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: order == null
          ? _buildNoActiveOrder(context, theme)
          : SafeArea(
              child: Column(
                children: [
                  // Map Viewport
                  Expanded(
                    flex: 6,
                    child: _buildFlutterMap(order),
                  ),

                  // Delivery Status Timeline & Rider card
                  Expanded(
                    flex: 7,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0, left: 16.0, right: 16.0),
                            child: _buildStatusTimeline(order.status),
                          ),
                          const Divider(color: Colors.black12, height: 24),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: order.status == OrderStatus.outForDelivery || order.status == OrderStatus.delivered
                                ? _buildRiderCard(order.rider, theme)
                                : Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F2F4),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6B35)),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Assigning Delivery Partner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              const SizedBox(height: 4),
                                              Text(
                                                order.status == OrderStatus.placed 
                                                    ? 'Waiting for merchant to accept.' 
                                                    : 'Please wait while we find a delivery partner for your order.', 
                                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFlutterMap(OrderModel order) {
    // Fallback for old orders that were placed before we updated to real coordinates
    var sLat = order.shop.location.x;
    var sLng = order.shop.location.y;
    if (sLat < 2.0 && sLng < 2.0) { sLat = 28.630; sLng = 77.218; }

    var cLat = order.customerLocation.x;
    var cLng = order.customerLocation.y;
    if (cLat < 2.0 && cLng < 2.0) { cLat = 28.524; cLng = 77.206; }

    final shopLoc = LatLng(sLat, sLng);
    final custLoc = LatLng(cLat, cLng);
    final riderLoc = LatLng(order.currentRiderPosition.x, order.currentRiderPosition.y);

    List<Marker> markers = [
      Marker(
        point: shopLoc,
        width: 80,
        height: 80,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)),
              child: const Text('Shop', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const Icon(Icons.store, color: Colors.orange, size: 30),
          ],
        ),
      ),
      Marker(
        point: custLoc,
        width: 80,
        height: 80,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red)),
              child: const Text('You', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const Icon(Icons.location_on, color: Colors.red, size: 30),
          ],
        ),
      ),
    ];

    if (order.status == OrderStatus.outForDelivery || order.status == OrderStatus.delivered) {
      markers.add(
        Marker(
          point: riderLoc,
          width: 80,
          height: 80,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue)),
                child: Text(order.rider.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.motorcycle, color: Colors.blue, size: 30),
            ],
          ),
        ),
      );
    }

    // Try to center camera between the two locations
    final centerLat = (shopLoc.latitude + custLoc.latitude) / 2;
    final centerLng = (shopLoc.longitude + custLoc.longitude) / 2;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(centerLat, centerLng),
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.nolate',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [shopLoc, custLoc],
                  color: const Color(0xFFFF6B35),
                  strokeWidth: 4.0,
                ),
              ],
            ),
            MarkerLayer(markers: markers),
          ],
        ),

        // Map Legend
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pedal_bike, size: 14, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  order.status == OrderStatus.outForDelivery || order.status == OrderStatus.delivered 
                      ? 'Rider tracking' : 'Finding rider...',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),

        // Coords / status overlay
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35), // Vibrant Orange
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: const Color(0xFFFF6B35).withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flash_on, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'Status: ${order.status.name.toUpperCase()}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoActiveOrder(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off_rounded, size: 70, color: Colors.black12),
          const SizedBox(height: 20),
          const Text(
            'No Active Order',
            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Go back to home and place an order first!',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669), // Deep Indigo
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

  Widget _buildStatusTimeline(OrderStatus status) {
    final steps = [
      {'label': 'Placed', 'status': OrderStatus.placed},
      {'label': 'Accepted', 'status': OrderStatus.accepted},
      {'label': 'Preparing', 'status': OrderStatus.preparing},
      {'label': 'Shipped', 'status': OrderStatus.outForDelivery},
      {'label': 'Delivered', 'status': OrderStatus.delivered},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final stepStatus = steps[index]['status'] as OrderStatus;
        final stepLabel = steps[index]['label'] as String;

        final isActive = stepStatus == status;
        final isCompleted = stepStatus.index <= status.index;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 0
                          ? Colors.transparent
                          : isCompleted
                              ? Colors.green
                              : Colors.black12,
                    ),
                  ),
                  Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green
                          : isActive
                              ? const Color(0xFFFF6B35) // Warm Coral
                              : Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? const Color(0xFFFF6B35) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 10, color: Colors.white)
                          : Container(
                              height: 5,
                              width: 5,
                              decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == steps.length - 1
                          ? Colors.transparent
                          : stepStatus.index < status.index
                              ? Colors.green
                              : Colors.black12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                stepLabel,
                style: TextStyle(
                  color: isCompleted ? Colors.black87 : Colors.black38,
                  fontSize: 10,
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRiderCard(Rider rider, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF059669).withValues(alpha: 0.1), // Deep Indigo tint
            foregroundColor: const Color(0xFF059669), // Deep Indigo
            child: const Icon(Icons.person, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.name,
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rider.vehicle} (${rider.vehicleNumber})',
                  style: const TextStyle(color: Colors.black45, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    rider.rating.toString(),
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.green, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      rider.phone,
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOrderDetailsDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Order Items (${order.items.length})',
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.quantity}x ${item.item.name}',
                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                      ),
                      Text(
                        '₹${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.black45)),
            ),
          ],
        );
      },
    );
  }
}
