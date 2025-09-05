import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service.dart';
import 'auth_service.dart';

class ServiceManager {
  static const String _baseUrl = 'http://10.0.2.2:8080/api/services';

  Future<List<Service>> fetchServices() async {
    try {
      final token = await AuthService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token'
      };

      final response = await http.get(Uri.parse(_baseUrl), headers: headers);
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Service.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load services: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching services: $e');
    }
  }

  // Updated: Propose a service with location
  Future<bool> proposeServiceWithLocation(
    String name, 
    String description, 
    double price,
    String location,
  ) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final Map<String, dynamic> data = {
        "name": name,
        "description": description,
        "location": location, // Include location
        "price": price,
        "votes": 0,
        "status": "pending"
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Error proposing service: $e');
    }
  }

  // Keep old method for compatibility
  Future<bool> proposeService(String name, String description, double price) async {
    return proposeServiceWithLocation(
      name, 
      description, 
      price, 
      "36.8065,10.1815", // Default location
    );
  }

  Future<Service> addService(Service service) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(service.toJson()),
      );

      if (response.statusCode == 201) {
        return Service.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add service: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding service: $e');
    }
  }

  Future<Service> updateService(Service service) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/${service.id}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(service.toJson()),
      );

      if (response.statusCode == 200) {
        return Service.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update service: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating service: $e');
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/$serviceId'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete service: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting service: $e');
    }
  }
}