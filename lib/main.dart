import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'utils/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Service Locator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryBlue,
        scaffoldBackgroundColor: AppColors.backgroundWhite,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.primaryBlue,
          secondary: AppColors.accentYellow,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const MainSwipingScreen(),
    );
  }
}

class MainSwipingScreen extends StatefulWidget {
  const MainSwipingScreen({super.key});

  @override
  State<MainSwipingScreen> createState() => _MainSwipingScreenState();
}

class _MainSwipingScreenState extends State<MainSwipingScreen> {
  final PageController _pageController = PageController(initialPage: 1);
  double _currentPage = 1.0;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!;
      });
    });
  }

  Future<void> _checkLoginStatus() async {
    final token = await AuthService.getToken();
    setState(() {
      _isLoggedIn = token != null;
    });
  }

  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _onLogout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (index) => _checkLoginStatus(),
            children: [
              // Login or Profile Screen based on auth status
              _isLoggedIn 
                ? ProfileScreen(onLogout: _onLogout)
                : LoginScreen(onLoginSuccess: _onLoginSuccess),
              
              // Map Screen
              MapScreen(pageController: _pageController),
            ],
          ),
          
          // Swipe Indicator for Map Screen
          if (_currentPage.round() == 1)
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: AnimatedOpacity(
                opacity: 1.0 - (_currentPage - 1).abs(),
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.swipe_left, 
                        color: AppColors.primaryBlue, 
                        size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _isLoggedIn ? 'Profile' : 'Login',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}