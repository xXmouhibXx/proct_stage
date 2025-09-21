import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/service_manager.dart';
import '../utils/app_colors.dart';

class ProposeServiceScreen extends StatefulWidget {
  const ProposeServiceScreen({super.key});

  @override
  State<ProposeServiceScreen> createState() => _ProposeServiceScreenState();
}

class _ProposeServiceScreenState extends State<ProposeServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Original controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  // New controllers for service product form
  final TextEditingController _ownerEmailController = TextEditingController();
  final TextEditingController _reservationLinkController = TextEditingController();
  final TextEditingController _providerController = TextEditingController();

  final ServiceManager _serviceManager = ServiceManager();
  
  bool _isLoading = false;
  String? _currentLocation;
  DateTime? _endDate;
  String? _selectedDelegation;
  String? _selectedSector;
  String? _selectedCategory;
  String? _selectedInstitution;
  
  // NEW: Location selection variables
  bool _useCurrentLocation = true;
  LatLng? _selectedMapLocation;
  final MapController _mapController = MapController();
  
  Map<String, List<String>> _sectors = {};
  Map<String, List<String>> _categories = {};
  
  final List<String> _delegations = [
    'جندوبة',
    'جندوبة الشمالية',
    'بوسالم',
    'طبرقة',
    'عين دراهم',
    'فرنانة',
    'غار الدماء',
    'وادي مليز',
    'بلطة بوعوان'
  ];

  @override
  void initState() {
    super.initState();
    _loadLocationData();
    _getCurrentLocation();
    
    // Debug print to verify data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Delegations: ${_delegations.length}');
      print('Categories: ${_categories.length}');
      print('Sectors: ${_sectors.length}');
    });
  }

  void _loadLocationData() {
    // Sectors data
    _sectors = {
      'جندوبة': ['الزغايدة', 'جندوبة الجنوبية', 'النور', 'السعادة', 'الملقى', 'التطور', 'سوق السبت'],
      'جندوبة الشمالية': ['العيثة', 'عين الكريمة', 'معلة', 'الجريف', 'العزيمة', 'الفردوس'],
      'بوسالم': ['بوسالم الشمالية', 'بوسالم الجنوبية', 'الروماني', 'البراهمي', 'المرجى'],
      'طبرقة': ['طبرقة', 'الريحان', 'الحامدية', 'الحمام', 'عين الصبح', 'الناظور', 'ملولة'],
      'عين دراهم': ['عين دراهم المدينة', 'عين دراهم الأحواز', 'أولاد سدرة', 'العطاطفة', 'الحمران'],
      'فرنانة': ['فرنانة', 'وادي غريب', 'ربيعة', 'أولاد مفدة', 'القوايدية', 'بني مطير'],
      'غار الدماء': ['غار الدماء', 'غار الدماء الشمالية', 'المعدن', 'الرخاء', 'عين سلطان'],
      'وادي مليز': ['واد مليز الشرقية', 'واد مليز الغربية', 'الدخايلية', 'حكيم الشمالية', 'حكيم الجنوبية'],
      'بلطة بوعوان': ['بلطة', 'عبد الجبار', 'بوعوان', 'وادي كساب', 'بولعابة']
    };

    // Categories data
    _categories = {
      'الأعمال الطبية': ['طبيب أسنان', 'طب الجلدية', 'طوارئ', 'أمراض نسائية', 'عيادة طبية', 
                          'أخصائي نظارات', 'بصريات', 'أنف أذن حنجرة', 'طب الأطفال', 'صيدلية'],
      'خدمات الطوارئ': ['مركز إطفاء', 'مستشفى', 'مركز شرطة'],
      'منشأة غذائية': ['مخبز', 'مقهى أو كافتيريا', 'مطعم وجبات سريعة'],
      'المكاتب الحكومية': ['مكتب بريد', 'البلدية', 'المعتمدية', 'القباضة', 'الولاية'],
      'أعمال المنازل والبناء': ['كهربائي', 'تكييف وتدفئة', 'شركة نقل', 'سباك'],
      'متجر': ['متجر قطع غيار السيارات', 'متجر ملابس', 'متجر إلكترونيات', 'متجر مستلزمات يومية'],
      'الخدمات المالية': ['خدمات محاسبة', 'صراف آلي', 'بنك أو اتحاد ائتماني', 'وكالة تأمين'],
      'الإقامة': ['مخيم', 'فندق', 'إيجار عطلات'],
      'الخدمات القانونية': ['محامي', 'كاتب عدل'],
      'الصحة والجمال': ['صالون تجميل', 'صالون حلاقة', 'صالون أظافر', 'صالون وشم'],
      'أخرى': ['أعمال ترفيهية', 'موقع نشاط رياضي', 'مأوى حيوانات', 'منظمة أرشيف']
    };
    
    // Force rebuild to ensure dropdowns are populated
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = "36.8065,10.1815";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = "36.8065,10.1815";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = "36.8065,10.1815";
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = "${position.latitude},${position.longitude}";
      });
    } catch (e) {
      print('Location error: $e');
      setState(() {
        _currentLocation = "36.8065,10.1815";
      });
    }
  }

  // NEW: Get coordinates for delegation
  LatLng _getDelegationCoordinates() {
    // Delegation center coordinates
    final Map<String, LatLng> delegationCoords = {
      'جندوبة': const LatLng(36.5019, 8.7802),
      'جندوبة الشمالية': const LatLng(36.5334, 8.7621),
      'بوسالم': const LatLng(36.6106, 8.9694),
      'طبرقة': const LatLng(36.9544, 8.7574),
      'عين دراهم': const LatLng(36.7756, 8.6883),
      'فرنانة': const LatLng(36.6652, 8.8183),
      'غار الدماء': const LatLng(36.4505, 8.4396),
      'وادي مليز': const LatLng(36.4620, 8.3547),
      'بلطة بوعوان': const LatLng(36.7236, 9.0842),
    };
    
    // More specific sector coordinates (if available)
    final Map<String, Map<String, LatLng>> sectorCoords = {
      'جندوبة': {
        'الزغايدة': const LatLng(36.5087, 8.7743),
        'جندوبة الجنوبية': const LatLng(36.4951, 8.7861),
        'النور': const LatLng(36.5056, 8.7789),
        'السعادة': const LatLng(36.5123, 8.7698),
        'الملقى': const LatLng(36.4989, 8.7923),
        'التطور': const LatLng(36.5145, 8.7756),
        'سوق السبت': const LatLng(36.4876, 8.7967),
      },
      'طبرقة': {
        'طبرقة': const LatLng(36.9544, 8.7574),
        'الريحان': const LatLng(36.9423, 8.7489),
        'الحامدية': const LatLng(36.9678, 8.7623),
        'الحمام': const LatLng(36.9589, 8.7701),
        'عين الصبح': const LatLng(36.9367, 8.7812),
        'الناظور': const LatLng(36.9712, 8.7456),
        'ملولة': const LatLng(36.9234, 8.7234),
      },
      // Add more sectors as needed
    };
    
    // Try to get sector-specific coordinates first
    if (_selectedDelegation != null && _selectedSector != null) {
      if (sectorCoords.containsKey(_selectedDelegation)) {
        if (sectorCoords[_selectedDelegation]!.containsKey(_selectedSector)) {
          return sectorCoords[_selectedDelegation]![_selectedSector]!;
        }
      }
    }
    
    // Fall back to delegation coordinates
    if (_selectedDelegation != null && delegationCoords.containsKey(_selectedDelegation)) {
      return delegationCoords[_selectedDelegation]!;
    }
    
    // Default to current location or Jendouba center
    if (_currentLocation != null) {
      List<String> parts = _currentLocation!.split(',');
      return LatLng(double.parse(parts[0]), double.parse(parts[1]));
    }
    
    return const LatLng(36.5019, 8.7802); // Default Jendouba
  }

  // NEW: Method to show map for location selection
  void _showMapPicker() {
    // Get appropriate center based on selected delegation/sector
    LatLng mapCenter = _getDelegationCoordinates();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'اختر موقع الخدمة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedDelegation != null || _selectedSector != null)
                            Text(
                              '${_selectedDelegation ?? ''} ${_selectedSector != null ? '- $_selectedSector' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Map
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedMapLocation ?? mapCenter,
                        initialZoom: _selectedSector != null ? 15.0 : 13.0, // Zoom more if sector selected
                        onTap: (tapPosition, latLng) {
                          setState(() {
                            _selectedMapLocation = latLng;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        if (_selectedMapLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedMapLocation!,
                                width: 60,
                                height: 60,
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.primaryBlue,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    
                    // Center indicator
                    if (_selectedMapLocation == null)
                      const Center(
                        child: Icon(
                          Icons.add_location,
                          size: 40,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    
                    // Instructions
                    Positioned(
                      top: 10,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedDelegation != null 
                            ? 'انقر على الخريطة لتحديد موقع الخدمة في ${_selectedDelegation}'
                            : 'انقر على الخريطة لتحديد موقع الخدمة',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submitService() async {
    if (!_formKey.currentState!.validate()) return;

    // NEW: Determine final location based on selection
    String finalLocation;
    if (_useCurrentLocation) {
      finalLocation = _currentLocation ?? "36.8065,10.1815";
    } else {
      if (_selectedMapLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تحديد موقع على الخريطة')),
        );
        return;
      }
      finalLocation = "${_selectedMapLocation!.latitude},${_selectedMapLocation!.longitude}";
    }

    setState(() => _isLoading = true);

    try {
      // Parse price safely with default value
      double price = 0.0;
      if (_priceController.text.isNotEmpty) {
        price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      }

      // Enhanced service proposal with all fields
      final success = await _serviceManager.proposeServiceWithFullDetails(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        location: finalLocation, // Use determined location
        ownerEmail: _ownerEmailController.text.trim(),
        endDate: _endDate,
        reservationLink: _reservationLinkController.text.trim(),
        delegation: _selectedDelegation,
        sector: _selectedSector,
        provider: _providerController.text.trim(),
        institution: _selectedInstitution,
        category: _selectedCategory,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الخدمة بنجاح!'),
            backgroundColor: AppColors.successColor,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في إضافة الخدمة.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('إضافة خدمة'),
        backgroundColor: AppColors.primaryBlue,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_business,
                  size: 50,
                  color: AppColors.primaryBlue,
                ),
              ),
              
              const SizedBox(height: 30),
              
              Text(
                "تسجيل المنتجات والخدمات",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Service Name
              _buildTextField(
                controller: _nameController,
                label: 'اسم الخدمة / المؤسسة',
                icon: Icons.business,
                validator: (value) => value!.isEmpty ? 'الرجاء إدخال اسم الخدمة' : null,
              ),
              const SizedBox(height: 16),

              // Owner Email
              _buildTextField(
                controller: _ownerEmailController,
                label: 'البريد الإلكتروني للمالك',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
                  if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value)) {
                    return 'البريد الإلكتروني غير صالح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Selection
              _buildDropdown(
                value: _selectedCategory,
                hint: 'الفئة',
                icon: Icons.category,
                items: _categories.keys.toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedInstitution = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Institution (based on category)
              if (_selectedCategory != null && _categories[_selectedCategory] != null) ...[
                _buildDropdown(
                  value: _selectedInstitution,
                  hint: 'المؤسسة',
                  icon: Icons.store,
                  items: _categories[_selectedCategory]!,
                  onChanged: (value) {
                    setState(() {
                      _selectedInstitution = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Provider
              _buildTextField(
                controller: _providerController,
                label: 'المزوّد',
                icon: Icons.person_pin,
              ),
              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'وصف المنتجات والخدمات',
                icon: Icons.description,
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'الرجاء إدخال وصف' : null,
              ),
              const SizedBox(height: 16),

              // Price (optional)
              _buildTextField(
                controller: _priceController,
                label: 'السعر (اختياري)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Reservation Link
              _buildTextField(
                controller: _reservationLinkController,
                label: 'رابط الحجز (اختياري)',
                icon: Icons.link,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // End Date
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                      const SizedBox(width: 12),
                      Text(
                        _endDate == null
                            ? 'تاريخ الإنشاء'
                            : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                        style: TextStyle(
                          color: _endDate == null ? AppColors.textLight : AppColors.textDark,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Delegation
              _buildDropdown(
                value: _selectedDelegation,
                hint: 'المعتمدية',
                icon: Icons.location_city,
                items: _delegations,
                onChanged: (value) {
                  setState(() {
                    _selectedDelegation = value;
                    _selectedSector = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Sector
              if (_selectedDelegation != null && _sectors[_selectedDelegation] != null) ...[
                _buildDropdown(
                  value: _selectedSector,
                  hint: 'العمادة',
                  icon: Icons.map,
                  items: _sectors[_selectedDelegation]!,
                  onChanged: (value) {
                    setState(() {
                      _selectedSector = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // NEW: Location selection section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'موقع الخدمة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Location option 1: Current location
                    RadioListTile<bool>(
                      title: Row(
                        children: [
                          const Icon(Icons.my_location, 
                            color: AppColors.primaryBlue,
                            size: 20),
                          const SizedBox(width: 8),
                          const Text('استخدام موقعي الحالي'),
                        ],
                      ),
                      subtitle: _currentLocation != null 
                        ? const Text('تم تحديد موقعك',
                            style: TextStyle(color: AppColors.successColor, fontSize: 12))
                        : const Text('جاري تحديد موقعك...',
                            style: TextStyle(fontSize: 12)),
                      value: true,
                      groupValue: _useCurrentLocation,
                      onChanged: (value) {
                        setState(() {
                          _useCurrentLocation = value!;
                        });
                      },
                      activeColor: AppColors.primaryBlue,
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    // Location option 2: Select on map
                    RadioListTile<bool>(
                      title: Row(
                        children: [
                          const Icon(Icons.location_on, 
                            color: AppColors.accentYellow,
                            size: 20),
                          const SizedBox(width: 8),
                          const Text('تحديد موقع على الخريطة'),
                        ],
                      ),
                      subtitle: _selectedMapLocation != null
                        ? Text('تم تحديد الموقع: ${_selectedMapLocation!.latitude.toStringAsFixed(4)}, ${_selectedMapLocation!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(color: AppColors.successColor, fontSize: 12))
                        : const Text('انقر لفتح الخريطة',
                            style: TextStyle(fontSize: 12)),
                      value: false,
                      groupValue: _useCurrentLocation,
                      onChanged: (value) {
                        setState(() {
                          _useCurrentLocation = value!;
                          if (!_useCurrentLocation) {
                            _showMapPicker();
                          }
                        });
                      },
                      activeColor: AppColors.primaryBlue,
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    // Map button if map option is selected
                    if (!_useCurrentLocation) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showMapPicker,
                          icon: const Icon(Icons.map),
                          label: Text(_selectedMapLocation != null 
                            ? 'تغيير الموقع' 
                            : 'فتح الخريطة'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.primaryBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Submit Button
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'إضافة الخدمة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primaryBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.pureWhite,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    // Debug print
    print('Building dropdown for $hint with ${items.length} items');
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryBlue),
          border: InputBorder.none,
        ),
        items: items.isEmpty 
          ? null 
          : items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
        onChanged: items.isEmpty ? null : onChanged,
        hint: Text(hint),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _ownerEmailController.dispose();
    _reservationLinkController.dispose();
    _providerController.dispose();
    _mapController.dispose(); 
    super.dispose();
  }
}