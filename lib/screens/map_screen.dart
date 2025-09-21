import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/service_manager.dart';
import '../services/auth_service.dart';
import '../models/service.dart';
import '../models/review.dart';
import '../utils/app_colors.dart';
import 'propose_service_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      if (token != null) {
        print('User is logged in');
      } else {
        print('User is not logged in');
      }
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
      print('Error fetching services: $e');
      setState(() => _isLoading = false);
    }
  }

  // Fetch reviews for a specific service with detailed debugging
  Future<List<Review>> _fetchServiceReviews(int serviceId) async {
    print('=== START _fetchServiceReviews for service ID: $serviceId ===');
    
    try {
      final url = 'http://10.0.2.2:8080/api/services/$serviceId/reviews';
      print('Calling URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('Decoded data type: ${data.runtimeType}');
        print('Number of reviews: ${data.length}');
        
        if (data.isNotEmpty) {
          print('First review data: ${data[0]}');
        }
        
        List<Review> reviews = data.map((json) {
          print('Parsing review: $json');
          return Review.fromJson(json);
        }).toList();
        
        print('Successfully parsed ${reviews.length} reviews');
        for (var review in reviews) {
          print('Review: ${review.clientName} - Rating: ${review.rating} - Comment: ${review.comment}');
        }
        
        return reviews;
      } else {
        print('ERROR: Non-200 status code: ${response.statusCode}');
        print('Error body: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('ERROR in _fetchServiceReviews: $e');
      print('Stack trace: $stackTrace');
    }
    
    print('Returning empty list');
    return [];
  }

  // Check if current user has reviewed the service
  Future<bool> _hasUserReviewed(int serviceId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/services/$serviceId/has-reviewed'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return data['hasReviewed'] ?? false;
      }
    } catch (e) {
      print('Error checking review status: $e');
    }
    return false;
  }

 // Replace the _getUserLocation method in map_screen.dart with this fixed version:
  
  Future<void> _getUserLocation() async {
    try {
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

      // Check if widget is still mounted before calling setState
      if (!mounted) return;

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _center = _userLocation!;
      });

      // Check again before moving the map
      if (mounted && _mapController != null) {
        _mapController.move(_center, 13.0);
      }
    } catch (e) {
      print('Error getting user location: $e');
    }
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
        const SnackBar(content: Text("الموقع غير موجود")),
      );
    }
  }

  // Show service information with reviews
  void _showServiceInformation(Service service) async {
    print('=== START _showServiceInformation for service: ${service.id} - ${service.name} ===');
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      print('About to fetch reviews...');
      // Fetch reviews
      final reviews = await _fetchServiceReviews(service.id);
      print('Reviews fetched successfully: ${reviews.length} reviews');
      
      print('About to check if user has reviewed...');
      final hasReviewed = await _hasUserReviewed(service.id);
      print('User has reviewed: $hasReviewed');

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show information sheet
      if (!mounted) return;
      
      print('Showing bottom sheet with ${reviews.length} reviews');
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: controller,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Business Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.accentYellow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.business,
                              color: AppColors.primaryBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                if (service.category != null)
                                  Text(
                                    service.category!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                              ],
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
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Business Details
                _buildInfoSection(
                  title: 'معلومات العمل',
                  children: [
                    if (service.provider != null && service.provider!.isNotEmpty)
                      _buildInfoRow(Icons.person, 'المزود', service.provider!),
                    if (service.institution != null && service.institution!.isNotEmpty)
                      _buildInfoRow(Icons.store, 'المؤسسة', service.institution!),
                    if (service.delegation != null && service.delegation!.isNotEmpty)
                      _buildInfoRow(Icons.location_city, 'المعتمدية', service.delegation!),
                    if (service.sector != null && service.sector!.isNotEmpty)
                      _buildInfoRow(Icons.map, 'العمادة', service.sector!),
                    if (service.ownerEmail != null && service.ownerEmail!.isNotEmpty)
                      _buildInfoRow(Icons.email, 'البريد الإلكتروني', service.ownerEmail!),
                    if (service.reservationLink != null && service.reservationLink!.isNotEmpty)
                      _buildInfoRow(Icons.link, 'رابط الحجز', service.reservationLink!),
                  ],
                ),

                const SizedBox(height: 20),

                // Rating Section
                _buildInfoSection(
                  title: 'التقييمات',
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.accentYellow,
                                size: 30,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${service.averageRating?.toStringAsFixed(1) ?? '0.0'} / 5.0',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${service.reviewCount ?? 0} تقييم',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Real Reviews
                    if (reviews.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        child: Text(
                          'لا توجد تقييمات بعد',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 16,
                          ),
                        ),
                      )
                    else
                      ...reviews.map((review) => _buildReviewCard(
                        name: review.clientName,
                        rating: review.rating,
                        comment: review.comment ?? '',
                        date: review.reviewDate,
                      )).toList(),
                  ],
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    // Add Review button (disabled if already reviewed)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_isLoggedIn && !hasReviewed) ? () {
                          Navigator.pop(context);
                          _showReviewDialog(service);
                        } : null,
                        icon: Icon(
                          hasReviewed ? Icons.check : Icons.rate_review,
                          size: 18
                        ),
                        label: Text(
                          hasReviewed ? 'تم التقييم' : 'إضافة تقييم'
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: (_isLoggedIn && !hasReviewed)
                              ? AppColors.primaryBlue
                              : Colors.grey,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Close button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('إغلاق'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
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
        ),
      );
    } catch (e, stackTrace) {
      print('ERROR in _showServiceInformation: $e');
      print('Stack trace: $stackTrace');
      
      // Close loading dialog on error
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String name,
    required double rating,
    required String comment,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: AppColors.accentYellow,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (comment.isNotEmpty)
            Text(
              comment,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // Add review dialog
  void _showReviewDialog(Service service) {
    final TextEditingController _commentController = TextEditingController();
    double _rating = 3.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Column(
                children: [
                  const Icon(
                    Icons.star_rate,
                    color: AppColors.accentYellow,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'تقييم ${service.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rating Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: AppColors.accentYellow,
                            size: 30,
                          ),
                          onPressed: () {
                            setState(() {
                              _rating = index + 1.0;
                            });
                          },
                        );
                      }),
                    ),
                    Text(
                      '${_rating.toStringAsFixed(1)} / 5.0',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Comment Field
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'التعليق',
                        hintText: 'شاركنا تجربتك...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.comment, color: AppColors.primaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _submitReview(
                      service: service,
                      rating: _rating,
                      comment: _commentController.text,
                    );
                    Navigator.of(context).pop();
                    // Refresh the information sheet
                    _showServiceInformation(service);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('إرسال', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Submit review method with better error handling
  Future<void> _submitReview({
    required Service service,
    required double rating,
    required String comment,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب تسجيل الدخول أولاً'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get user email safely
      String userEmail = 'user@example.com';
      try {
        final profileResult = await AuthService.getProfile();
        if (profileResult['success'] == true && 
            profileResult['data'] != null &&
            profileResult['data']['email'] != null) {
          userEmail = profileResult['data']['email'];
        }
      } catch (e) {
        print('Error getting user email: $e');
      }

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/services/${service.id}/review'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'clientEmail': userEmail,
          'provider': service.provider ?? service.name,
          'serviceProposalId': service.id,
          'bookingStartDate': DateTime.now().subtract(const Duration(days: 7)).toIso8601String().split('T')[0],
          'bookingEndDate': DateTime.now().toIso8601String().split('T')[0],
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة التقييم بنجاح'),
            backgroundColor: AppColors.successColor,
          ),
        );
        // Refresh services to show updated rating
        _fetchServices();
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['error'] ?? 'فشل إضافة التقييم'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
                // Review button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoggedIn ? () {
                      Navigator.pop(context);
                      _showReviewDialog(service);
                    } : null,
                    icon: const Icon(Icons.star, size: 18),
                    label: const Text('تقييم'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: _isLoggedIn ? AppColors.accentYellow : Colors.grey,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // View Information button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showServiceInformation(service);
                    },
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('رؤية المعلومات'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textLight,
                ),
              ),
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
                  hintText: 'البحث عن موقع...',
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
                      'سجل الدخول لإضافة الخدمات',
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