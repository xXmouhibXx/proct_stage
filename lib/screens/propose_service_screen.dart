import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
      'وادي مليز': ['واد مليز الشرقية', 'واد مليز الغريبة', 'الدخايلية', 'حكيم الشمالية', 'حكيم الجنوبية'],
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
        location: _currentLocation ?? "36.8065,10.1815",
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
              
              // Location indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, 
                      color: AppColors.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentLocation != null 
                          ? 'سيتم إضافة الخدمة في موقعك الحالي'
                          : 'جاري تحديد موقعك...',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_currentLocation == null)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                        ),
                      ),
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
    super.dispose();
  }
}