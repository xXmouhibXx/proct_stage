import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/service_manager.dart';
import '../services/auth_service.dart';
import '../models/service.dart';
import '../utils/app_colors.dart';
import 'propose_service_screen.dart';

class MapScreen extends StatefulWidget {
  final PageController? pageController;
  const MapScreen({Key? key, this.pageController}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final ServiceManager _serviceManager = ServiceManager();
  final TextEditingController _searchController = TextEditingController();

  LatLng _center = const LatLng(36.5019, 8.7802); // Jendouba
  LatLng? _userLocation;
  List<Service> _services = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchServices();
    _getUserLocation();
  }

  Future<void> _checkLoginStatus() async {
    final token = await AuthService.getToken();
    if (mounted) {
      setState(() => _isLoggedIn = token != null);
    }
  }

  Future<void> _fetchServices() async {
    try {
      final services = await _serviceManager.fetchServices();
      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
      _center = _userLocation!;
    });

    _mapController.move(_center, 13.0);
  }

  Future<void> _searchLocation(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final latLng =
            LatLng(locations.first.latitude, locations.first.longitude);
        setState(() => _center = latLng);
        _mapController.move(latLng, 13.0);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not found")),
      );
    }
  }

  void _showServiceDetails(Service service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              service.description,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoggedIn ? () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to cart!')),
                      );
                    } : () {
                      Navigator.pop(context);
                      widget.pageController?.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please login first')),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart, size: 18),
                    label: Text(_isLoggedIn ? 'Add to Cart' : 'Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentYellow,
                      foregroundColor: AppColors.textDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: _services
                    .map((service) => Marker(
                          point: LatLng(service.latitude, service.longitude),
                          width: 60,
                          height: 60,
                          child: GestureDetector(
                            onTap: () => _showServiceDetails(service),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.accentYellow,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryBlue,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: AppColors.primaryBlue,
                                size: 30,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80,
                      height: 80,
                      point: _userLocation!,
                      child: const Icon(
                        Icons.my_location,
                        color: AppColors.primaryBlue,
                        size: 35,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Top Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search location...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: AppColors.accentYellow),
                    onPressed: () => _searchLocation(_searchController.text.trim()),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                onSubmitted: _searchLocation,
              ),
            ),
          ),

          // Bottom Action Buttons
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // My Location Button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: "locateBtn",
                    onPressed: _getUserLocation,
                    backgroundColor: AppColors.pureWhite,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                
                // Add Service Button - Only shown when logged in
                if (_isLoggedIn) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.accentYellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentYellow.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      heroTag: "addServiceBtn",
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProposeServiceScreen(),
                          ),
                        );
                        _fetchServices(); // Refresh services after adding
                      },
                      backgroundColor: AppColors.accentYellow,
                      child: const Icon(
                        Icons.add,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Login Prompt for non-authenticated users
          if (!_isLoggedIn)
            Positioned(
              bottom: 30,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.info_outline, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Login to add services',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}