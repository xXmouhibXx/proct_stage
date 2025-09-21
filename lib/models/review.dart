class Review {
  final int id;
  final String clientName;
  final String clientEmail;
  final double rating;
  final String? comment;
  final String reviewDate;
  final String? createdAt;

  Review({
    required this.id,
    required this.clientName,
    required this.clientEmail,
    required this.rating,
    this.comment,
    required this.reviewDate,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      clientName: json['clientName'],
      clientEmail: json['clientEmail'],
      rating: json['rating']?.toDouble() ?? 0.0,
      comment: json['comment'],
      reviewDate: json['reviewDate'] ?? '',
      createdAt: json['createdAt'],
    );
  }
}