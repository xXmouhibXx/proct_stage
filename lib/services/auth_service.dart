// auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://10.0.2.2:8080/api/auth";
  static const String clientUrl = "http://10.0.2.2:8080/api/clients";

  // Token management
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    print('Token saved: ${token.substring(0, 20)}...');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      print('Token retrieved: ${token.substring(0, 20)}...');
    } else {
      print('No token found');
    }
    return token;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    print('Token cleared');
  }

  // Auth methods
  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': data['error'] ?? 'Registration failed'};
    } catch (e) {
      print('Registration error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // New method for client registration with all fields
  static Future<Map<String, dynamic>> registerClient({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required DateTime birthDate,
    String? gender,
    String? delegation,
    String? sector,
  }) async {
    try {
      // First register in the main auth system
      final authResponse = await register(fullName, email, password);
      
      if (!authResponse['success']) {
        return authResponse;
      }

      // Then register client details if you have a separate endpoint
      // For now, the main registration should handle everything
      return authResponse;
    } catch (e) {
      print('Client registration error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting login for: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password
        }),
      );

      print('Login response status: ${response.statusCode}');
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await saveToken(data['token']);
          print('Login successful, token saved');
        }
        return {'success': true, 'data': data};
      }
      
      print('Login failed: ${data['error']}');
      return {'success': false, 'error': data['error'] ?? 'Login failed'};
    } catch (e) {
      print('Login exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'error': data['error']};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        print('No token found for profile request');
        return {
          'success': false,
          'error': 'Not authenticated',
          'data': null
        };
      }

      print('Fetching profile with token');
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      print('Profile response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        print('Token expired or invalid');
        await clearToken();
        return {
          'success': false,
          'error': 'Session expired. Please login again.',
          'data': null
        };
      } else if (response.statusCode == 404) {
        print('User not found');
        return {
          'success': false,
          'error': 'User not found',
          'data': null
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to get profile',
          'data': null
        };
      }
    } catch (e) {
      print('Profile fetch exception: $e');
      return {
        'success': false,
        'error': e.toString(),
        'data': null
      };
    }
  }
}