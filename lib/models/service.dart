class Service {
  final String? id; // Nullable for creation
  final String name;
  final String description;
  final String location; // Stored as "lat,long" string
  final String? proposedById; // For proposal creation

  Service({
    this.id,
    required this.name,
    required this.description,
    required this.location,
    this.proposedById,
  });

  /// Getter for latitude
  double get latitude {
    final parts = location.split(',');
    return double.tryParse(parts[0]) ?? 0.0;
  }

  /// Getter for longitude
  double get longitude {
    final parts = location.split(',');
    return double.tryParse(parts.length > 1 ? parts[1] : '0.0') ?? 0.0;
  }

  /// Getter for both coordinates as a tuple
  (double, double) get coordinates => (latitude, longitude);

  // For regular service responses (without proposal info)
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '0.0,0.0', // Default location
    );
  }

  // For creating proposals (matches ServiceProposalDTO exactly)
  Map<String, dynamic> toProposalJson() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'proposedById': proposedById, // Set when creating proposals
    };
  }

  // For general service updates
  Map<String, dynamic> toJson() => toProposalJson(); // Same structure

  // Helper to create a proposal-ready service
  Service asProposal(String userId) {
    return Service(
      name: name,
      description: description,
      location: location,
      proposedById: userId,
    );
  }
}
