class Travel {
  final int id;
  final String title;
  final String? description;
  final String location;
  final String? country;
  final String? city;
  final String? image;
  final String? travelDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Travel({
    required this.id,
    required this.title,
    this.description,
    required this.location,
    this.country,
    this.city,
    this.image,
    this.travelDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Travel.fromJson(Map<String, dynamic> json) {
    return Travel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      location: json['location'] ?? '',
      country: json['country'],
      city: json['city'],
      image: json['image'],
      travelDate: json['travel_date'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'country': country,
      'city': city,
      'imageBase64': image,
      'travelDate': travelDate,
    };
  }
}

