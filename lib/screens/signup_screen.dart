// signup_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  DateTime? _birthDate;
  String? _selectedGender;
  String? _selectedDelegation;
  String? _selectedSector;

  bool _isLoading = false;
  bool _obscurePassword = true;

  Map<String, List<String>> _sectors = {};
  
  final List<String> _genders = ['ذكر', 'أنثى'];
  
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
  }

  void _loadLocationData() {
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
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار تاريخ الميلاد')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // First register as client in the new clients table
      final clientResult = await AuthService.registerClient(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phone: _phoneController.text.trim(),
        birthDate: _birthDate!,
        gender: _selectedGender,
        delegation: _selectedDelegation,
        sector: _selectedSector,
      );

      // Also register in the accounts table for authentication
      final result = await AuthService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الحساب بنجاح!'),
            backgroundColor: AppColors.successColor,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'فشل التسجيل. حاول مرة أخرى.')),
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
        backgroundColor: AppColors.primaryBlue,
        title: const Text('إنشاء حساب'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add,
                  size: 50,
                  color: AppColors.primaryBlue,
                ),
              ),
              
              const SizedBox(height: 30),
              
              Text(
                "انضم إلينا",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                "أنشئ حسابك للبدء",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Name Field (الاسم الكامل)
              Container(
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
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم الكامل',
                    prefixIcon: const Icon(Icons.person_outline,
                      color: AppColors.primaryBlue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.pureWhite,
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'الرجاء إدخال اسمك' : null,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Email Field (البريد الإلكتروني)
              Container(
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
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.primaryBlue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.pureWhite,
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
                    if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value)) {
                      return 'البريد الإلكتروني غير صالح';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Password Field (كلمة المرور)
              Container(
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
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.primaryBlue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textLight,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.pureWhite,
                  ),
                  validator: (value) =>
                      value!.length < 6 ? 'كلمة المرور يجب أن تكون 6+ أحرف' : null,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Phone Field (رقم الهاتف)
              Container(
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
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: const Icon(Icons.phone,
                      color: AppColors.primaryBlue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.pureWhite,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Birth Date (تاريخ الميلاد)
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
                        _birthDate == null
                            ? 'تاريخ الميلاد'
                            : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                        style: TextStyle(
                          color: _birthDate == null ? AppColors.textLight : AppColors.textDark,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Gender (الجنس)
              Container(
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
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'الجنس',
                    prefixIcon: const Icon(Icons.people, color: AppColors.primaryBlue),
                    border: InputBorder.none,
                  ),
                  items: _genders.map((gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Delegation (المعتمدية)
              Container(
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
                  value: _selectedDelegation,
                  decoration: InputDecoration(
                    labelText: 'المعتمدية',
                    prefixIcon: const Icon(Icons.location_city, color: AppColors.primaryBlue),
                    border: InputBorder.none,
                  ),
                  items: _delegations.map((delegation) {
                    return DropdownMenuItem<String>(
                      value: delegation,
                      child: Text(delegation),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDelegation = value;
                      _selectedSector = null; // Reset sector when delegation changes
                    });
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sector (العمادة)
              if (_selectedDelegation != null && _sectors[_selectedDelegation] != null)
                Container(
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
                    value: _selectedSector,
                    decoration: InputDecoration(
                      labelText: 'العمادة',
                      prefixIcon: const Icon(Icons.map, color: AppColors.primaryBlue),
                      border: InputBorder.none,
                    ),
                    items: _sectors[_selectedDelegation]!.map((sector) {
                      return DropdownMenuItem<String>(
                        value: sector,
                        child: Text(sector),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSector = value;
                      });
                    },
                  ),
                ),
              
              const SizedBox(height: 30),
              
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accentYellow,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentYellow.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textDark),
                        )
                      : const Text(
                          'إنشاء حساب',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}