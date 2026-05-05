class RestaurantModel {
  final String id;
  final String name;
  final String? city;
  final String? logo;

  RestaurantModel({
    required this.id,
    required this.name,
    this.city,
    this.logo,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'],
      logo: json['logoUrl'],
    );
  }
}