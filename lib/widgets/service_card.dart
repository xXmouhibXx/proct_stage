import 'package:flutter/material.dart';
import '../models/service.dart';

class ServiceCard extends StatelessWidget {
  final Service service;

  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(service.name),
        subtitle: Text(service.description),
      ),
    );
  }
}
