import 'package:flutter/material.dart';
import '../models/models.dart';

class LocationPickerSheet extends StatefulWidget {
  final String currentAddress;
  final Function(String address, Coordinate coordinate) onLocationSelected;

  const LocationPickerSheet({
    super.key,
    required this.currentAddress,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _allMockSuggestions = [
    {
      'name': 'Sector 62, Noida',
      'full': 'Sector 62, Noida, Uttar Pradesh 201309, India',
      'x': '28.625',
      'y': '77.370',
    },
    {
      'name': 'Saket Metro Station',
      'full': 'Saket, New Delhi, Delhi 110017, India',
      'x': '28.524',
      'y': '77.206',
    },
    {
      'name': 'Rajouri Garden',
      'full': 'Rajouri Garden, New Delhi, Delhi 110027, India',
      'x': '28.641',
      'y': '77.121',
    },
    {
      'name': 'Indirapuram',
      'full': 'Indirapuram, Ghaziabad, Uttar Pradesh 201014, India',
      'x': '28.638',
      'y': '77.372',
    },
    {
      'name': 'DLF Cyber City',
      'full': 'DLF Phase 3, Gurugram, Haryana 122002, India',
      'x': '28.490',
      'y': '77.088',
    },
    {
      'name': 'Green Park',
      'full': '123, Green Park Enclave, New Delhi 110016, India',
      'x': '28.558',
      'y': '77.202',
    },
    {
      'name': 'Noida Sector 15',
      'full': 'Sector 15, Noida, Uttar Pradesh 201301, India',
      'x': '28.580',
      'y': '77.310',
    },
    {
      'name': 'Connaught Place',
      'full': 'Connaught Place, New Delhi, Delhi 110001, India',
      'x': '28.630',
      'y': '77.218',
    },
  ];

  final List<Map<String, String>> _savedAddresses = [];

  final List<Map<String, String>> _recentLocations = [
    {
      'name': 'Sector 15, Noida',
      'full': 'Sector 15, Noida, Uttar Pradesh, India',
      'x': '28.580',
      'y': '77.310',
    },
    {
      'name': 'Connaught Place',
      'full': 'Connaught Place, New Delhi, India',
      'x': '28.630',
      'y': '77.218',
    },
  ];

  List<Map<String, String>> get _filteredSuggestions {
    if (_searchQuery.trim().isEmpty) return [];
    return _allMockSuggestions.where((loc) {
      return loc['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          loc['full']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showSuggestions = _searchQuery.trim().isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select delivery location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E), // Dark Navy
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF059669), // Deep Indigo
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search, color: Color(0xFF059669), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: const InputDecoration(
                        hintText: 'Search for area, street name...',
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: showSuggestions
                  ? _buildSuggestionsList()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Use current location
                        _buildOptionTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F0FF), // Soft Lavender tint
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.my_location, color: Color(0xFFFF6B35), size: 20), // Warm Coral icon
                          ),
                          title: 'Use current location',
                          titleColor: const Color(0xFF059669), // Deep Indigo title
                          titleWeight: FontWeight.bold,
                          onTap: () {
                            widget.onLocationSelected('Current Location', const Coordinate(28.630, 77.218));
                            Navigator.of(context).pop();
                          },
                        ),

                        // Add new address
                        _buildOptionTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F0FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add, color: Color(0xFF059669), size: 22),
                          ),
                          title: 'Add new address',
                          titleColor: const Color(0xFF059669),
                          titleWeight: FontWeight.bold,
                          onTap: () => Navigator.of(context).pop(),
                        ),



                        const SizedBox(height: 8),

                        if (_savedAddresses.isNotEmpty) ...[
                          // Saved Addresses
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Text(
                              'Your saved addresses',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
                            ),
                            child: Column(
                              children: _savedAddresses.asMap().entries.map((entry) {
                                final i = entry.key;
                                final addr = entry.value;
                                return Column(
                                  children: [
                                    _buildSavedAddressTile(addr, context),
                                    if (i < _savedAddresses.length - 1)
                                      const Divider(height: 1, indent: 16, endIndent: 16),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Recently Searched
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Text(
                            'Recently searched locations',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
                          ),
                          child: Column(
                            children: _recentLocations.asMap().entries.map((entry) {
                              final i = entry.key;
                              final loc = entry.value;
                              final double x = double.parse(loc['x']!);
                              final double y = double.parse(loc['y']!);
                              return Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      widget.onLocationSelected(loc['name']!, Coordinate(x, y));
                                      Navigator.of(context).pop();
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F0FF),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.location_on_outlined, color: Color(0xFFFF6B35), size: 20),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  loc['name']!,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  loc['full']!,
                                                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (i < _recentLocations.length - 1)
                                    const Divider(height: 1, indent: 16, endIndent: 16),
                                ],
                              );
                            }).toList(),
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

  Widget _buildSuggestionsList() {
    final suggestions = _filteredSuggestions;

    if (suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded, size: 48, color: const Color(0xFF059669).withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              const Text(
                'No locations found',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              const Text(
                'Try searching for Sector 62, Saket, Rajouri Garden, or DLF Cyber City.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black38),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: suggestions.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final loc = suggestions[index];
        final double x = double.parse(loc['x']!);
        final double y = double.parse(loc['y']!);

        return InkWell(
          onTap: () {
            widget.onLocationSelected(loc['full']!, Coordinate(x, y));
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on_outlined, color: Color(0xFFFF6B35), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc['name']!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc['full']!,
                        style: const TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required Widget leading,
    required String title,
    Color titleColor = Colors.black87,
    FontWeight titleWeight = FontWeight.w500,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: titleColor,
                  fontWeight: titleWeight,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedAddressTile(Map<String, String> addr, BuildContext context) {
    IconData iconData;
    switch (addr['icon']) {
      case 'home':
        iconData = Icons.home_outlined;
        break;
      case 'work':
        iconData = Icons.work_outline;
        break;
      default:
        iconData = Icons.location_on_outlined;
    }

    final double x = double.parse(addr['x']!);
    final double y = double.parse(addr['y']!);

    return InkWell(
      onTap: () {
        widget.onLocationSelected('${addr['type']!}, ${addr['full']!.split(',')[0]}', Coordinate(x, y));
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(iconData, color: const Color(0xFFFF6B35), size: 22),
                  if (addr['distance'] != null)
                    Positioned(
                      bottom: 2,
                      child: Text(
                        addr['distance']!,
                        style: const TextStyle(fontSize: 6, color: Color(0xFFFF6B35), fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    addr['type']!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    addr['full']!,
                    style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                  ),
                  if (addr['phone'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Phone number: ${addr['phone']}',
                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                  if (addr['distance'] != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.near_me_outlined, size: 12, color: Colors.black45),
                        const SizedBox(width: 4),
                        Text(
                          addr['distance']!,
                          style: const TextStyle(fontSize: 11, color: Colors.black45),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.star_border, color: Colors.black26, size: 18),
          ],
        ),
      ),
    );
  }
}
