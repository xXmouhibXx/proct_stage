import 'package:flutter/material.dart';

class ServiceMarker extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String label;

  const ServiceMarker({super.key, required this.latitude, required this.longitude, required this.label});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.location_pin, color: Colors.red);
  }
}
