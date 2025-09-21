class Service {
  final int id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final int votes;
  final String? ownerEmail;
  final String? endDate;
  final String? reservationLink;
  final String? delegation;
  final String? sector;
  final String? provider;
  final String? institution;
  final String? category;
  final double? averageRating;
  final int? reviewCount;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.votes = 0,
    this.ownerEmail,
    this.endDate,
    this.reservationLink,
    this.delegation,
    this.sector,
    this.provider,
    this.institution,
    this.category,
    this.averageRating,
    this.reviewCount,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    // Parse location string "lat,lon"
    List<String> locationParts = (json['location'] ?? '36.81,10.17').split(',');
    double lat = double.tryParse(locationParts[0]) ?? 36.81;
    double lon = double.tryParse(locationParts[1]) ?? 10.17;

    return Service(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      latitude: lat,
      longitude: lon,
      votes: json['votes'] ?? 0,
      ownerEmail: json['ownerEmail'],
      endDate: json['endDate']?.toString(),
      reservationLink: json['reservationLink'],
      delegation: json['delegation'],
      sector: json['sector'],
      provider: json['provider'],
      institution: json['institution'],
      category: json['category'],
      averageRating: json['averageRating']?.toDouble(),
      reviewCount: json['reviewCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': '$latitude,$longitude',
      'votes': votes,
      'ownerEmail': ownerEmail,
      'endDate': endDate,
      'reservationLink': reservationLink,
      'delegation': delegation,
      'sector': sector,
      'provider': provider,
      'institution': institution,
      'category': category,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
    };
  }
}