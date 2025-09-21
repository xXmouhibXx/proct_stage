import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service.dart';
import 'auth_service.dart';

class ServiceManager {
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // Fetch all services
  Future<List<Service>> fetchServices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Service.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load services');
      }
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  // Propose a new service with basic details
  Future<bool> proposeService({
    required String name,
    required String description,
    required double price,
    String? location,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('No auth token found');
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/services'), // FIXED: Using /services endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'price': price,
          'location': location ?? '36.8065,10.1815',
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error proposing service: $e');
      return false;
    }
  }

  // Propose a new service with full details (for service product registration)
  Future<bool> proposeServiceWithFullDetails({
    required String name,
    required String description,
    required double price,
    String? location,
    String? ownerEmail,
    DateTime? endDate,
    String? reservationLink,
    String? delegation,
    String? sector,
    String? provider,
    String? institution,
    String? category,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('No auth token found');
        return false;
      }

      // Build the request body with all fields
      Map<String, dynamic> requestBody = {
        'name': name,
        'description': description,
        'location': location ?? '36.8065,10.1815',
      };

      // Add optional fields if provided
      if (price > 0) requestBody['price'] = price;
      if (ownerEmail != null && ownerEmail.isNotEmpty) {
        requestBody['ownerEmail'] = ownerEmail;
      }
      if (endDate != null) {
        requestBody['endDate'] = endDate.toIso8601String().split('T')[0];
      }
      if (reservationLink != null && reservationLink.isNotEmpty) {
        requestBody['reservationLink'] = reservationLink;
      }
      if (delegation != null && delegation.isNotEmpty) {
        requestBody['delegation'] = delegation;
      }
      if (sector != null && sector.isNotEmpty) {
        requestBody['sector'] = sector;
      }
      if (provider != null && provider.isNotEmpty) {
        requestBody['provider'] = provider;
      }
      if (institution != null && institution.isNotEmpty) {
        requestBody['institution'] = institution;
      }
      if (category != null && category.isNotEmpty) {
        requestBody['category'] = category;
      }

      print('Sending service proposal: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/services'), // FIXED: Using /services endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Failed to create service: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error proposing service with full details: $e');
      return false;
    }
  }

  // Vote for a service
  Future<bool> voteForService(int serviceId) async {
    try {
      final token = await AuthService.getToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/services/$serviceId/vote'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error voting for service: $e');
      return false;
    }
  }

  // Add a review for a service
  Future<bool> addReview({
    required int serviceId,
    required String clientEmail,
    required String provider,
    required double rating,
    String? comment,
    DateTime? bookingStartDate,
    DateTime? bookingEndDate,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('No auth token found');
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/services/$serviceId/review'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'clientEmail': clientEmail,
          'provider': provider,
          'serviceProposalId': serviceId,
          'bookingStartDate': bookingStartDate?.toIso8601String().split('T')[0] ?? 
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String().split('T')[0],
          'bookingEndDate': bookingEndDate?.toIso8601String().split('T')[0] ?? 
            DateTime.now().toIso8601String().split('T')[0],
          'rating': rating,
          'comment': comment ?? '',
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
  }

  // Update a service
  Future<bool> updateService({
    required int serviceId,
    required String name,
    required String description,
    String? location,
    String? ownerEmail,
    DateTime? endDate,
    String? reservationLink,
    String? delegation,
    String? sector,
    String? provider,
    String? institution,
    String? category,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('No auth token found');
        return false;
      }

      Map<String, dynamic> requestBody = {
        'name': name,
        'description': description,
        'location': location ?? '36.8065,10.1815',
      };

      // Add optional fields
      if (ownerEmail != null) requestBody['ownerEmail'] = ownerEmail;
      if (endDate != null) requestBody['endDate'] = endDate.toIso8601String().split('T')[0];
      if (reservationLink != null) requestBody['reservationLink'] = reservationLink;
      if (delegation != null) requestBody['delegation'] = delegation;
      if (sector != null) requestBody['sector'] = sector;
      if (provider != null) requestBody['provider'] = provider;
      if (institution != null) requestBody['institution'] = institution;
      if (category != null) requestBody['category'] = category;

      final response = await http.put(
        Uri.parse('$baseUrl/services/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating service: $e');
      return false;
    }
  }

  // Delete a service
  Future<bool> deleteService(int serviceId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('No auth token found');
        return false;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/services/$serviceId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Error deleting service: $e');
      return false;
    }
  }
}