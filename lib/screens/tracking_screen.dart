import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/models.dart';
import 'home_screen.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final theme = Theme.of(context);
    final order = orderProvider.activeOrder;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F4), // Light background
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
              child: const Text('Items', style: TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: order == null
          ? _buildNoActiveOrder(context, theme)
          : SafeArea(
              child: Column(
                children: [
                  // Vector Map Viewport (Light representation)
                  Expanded(
                    flex: 6,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final height = constraints.maxHeight;

                        return Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                color: const Color(0xFFE2E8F0), // Light slate map bg
                                child: CustomPaint(
                                  painter: MapPainter(
                                    shopLocation: order.shop.location,
                                    customerLocation: order.customerLocation,
                                    riderLocation: order.currentRiderPosition,
                                  ),
                                ),
                              ),
                            ),

                            _buildMarker(
                              coord: order.shop.location,
                              label: '🏪 ${order.shop.name}',
                              color: const Color(0xFF0C831F), // Zoodo Green
                              width: width,
                              height: height,
                            ),

                            _buildMarker(
                              coord: order.customerLocation,
                              label: '🏠 Home',
                              color: Colors.redAccent,
                              width: width,
                              height: height,
                            ),

                            _buildMarker(
                              coord: order.currentRiderPosition,
                              label: '🛵 ${order.rider.name}',
                              color: Colors.orangeAccent,
                              isRider: true,
                              width: width,
                              height: height,
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
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.directions_bike_rounded, color: Colors.orangeAccent, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Rider tracking', 
                                      style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
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
                                  color: const Color(0xFF0C831F),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.flash_on_rounded, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      order.status == OrderStatus.outForDelivery
                                          ? 'Moving: ${(orderProvider.deliveryProgress * 100).toInt()}%'
                                          : 'Status: ${order.status.name.toUpperCase()}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
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
                            child: _buildRiderCard(order.rider, theme),
                          ),
                          
                          const Spacer(),

                          _buildSimulatorPanel(context, orderProvider, order, theme),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
              backgroundColor: const Color(0xFF0C831F),
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

  Widget _buildMarker({
    required Coordinate coord,
    required String label,
    required Color color,
    required double width,
    required double height,
    bool isRider = false,
  }) {
    final double left = coord.x * width;
    final double top = coord.y * height;

    return Positioned(
      left: left - (isRider ? 24 : 12),
      top: top - (isRider ? 32 : 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          Icon(
            isRider ? Icons.directions_bike_rounded : Icons.location_pin,
            color: color,
            size: isRider ? 28 : 24,
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
                              ? const Color(0xFF0C831F)
                              : Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? const Color(0xFF0C831F) : Colors.transparent,
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
            backgroundColor: const Color(0xFF0C831F).withValues(alpha: 0.1),
            foregroundColor: const Color(0xFF0C831F),
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

  Widget _buildSimulatorPanel(
    BuildContext context,
    OrderProvider orderProvider,
    OrderModel order,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F4), // Light console background
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.settings_suggest_rounded, color: Color(0xFF0C831F), size: 18),
              SizedBox(width: 6),
              Text(
                'Simulation Operator Panel',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimButton('Accept', () => orderProvider.updateOrderStatus(OrderStatus.accepted), order.status == OrderStatus.placed),
              _buildSimButton('Prepare', () => orderProvider.updateOrderStatus(OrderStatus.preparing), order.status == OrderStatus.accepted),
              _buildSimButton('Ship Out', () => orderProvider.updateOrderStatus(OrderStatus.outForDelivery), order.status == OrderStatus.preparing),
              _buildSimButton('Deliver', () => orderProvider.updateOrderStatus(OrderStatus.delivered), order.status == OrderStatus.outForDelivery),
            ],
          ),
          const SizedBox(height: 10),
          
          Row(
            children: [
              const Text('Manual Route:', style: TextStyle(color: Colors.black54, fontSize: 10)),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: orderProvider.deliveryProgress,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (val) {
                    orderProvider.setManualProgress(val);
                  },
                  activeColor: const Color(0xFF0C831F),
                  inactiveColor: Colors.black12,
                ),
              ),
              Text(
                '${(orderProvider.deliveryProgress * 100).toInt()}%',
                style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimButton(String label, VoidCallback onPressed, bool active) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: ElevatedButton(
          onPressed: active ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: active ? Colors.white : Colors.black.withValues(alpha: 0.02),
            foregroundColor: active ? const Color(0xFF0C831F) : Colors.black26,
            disabledBackgroundColor: Colors.black.withValues(alpha: 0.01),
            disabledForegroundColor: Colors.black12,
            elevation: active ? 1 : 0,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: active ? const Color(0xFF0C831F) : Colors.transparent,
                width: 1.0,
              ),
            ),
          ),
          child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ),
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

class MapPainter extends CustomPainter {
  final Coordinate shopLocation;
  final Coordinate customerLocation;
  final Coordinate riderLocation;

  MapPainter({
    required this.shopLocation,
    required this.customerLocation,
    required this.riderLocation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (double i = 0.0; i < size.width; i += 40.0) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0.0; j < size.height; j += 40.0) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }

    // River (Light Blue)
    final waterPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.08)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.45), Offset(size.width, size.height * 0.55), waterPaint);

    // Route path (Zoodo Green)
    final routePaint = Paint()
      ..color = const Color(0xFF0C831F).withValues(alpha: 0.3)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double sx = shopLocation.x * size.width;
    final double sy = shopLocation.y * size.height;
    final double cx = customerLocation.x * size.width;
    final double cy = customerLocation.y * size.height;

    final path = Path()
      ..moveTo(sx, sy)
      ..lineTo(cx, sy)
      ..lineTo(cx, cy);

    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
