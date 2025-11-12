class News {
  final String typename;
  final String imageBase64;

  News({required this.typename, required this.imageBase64});

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      typename: json['typename'] ?? '',
      imageBase64: json['image'] ?? '',
    );
  }
}
