// File: lib/models/order_ojek_models.dart

class OsmPlace {
  final String placeId;
  final double lat;
  final double lon;
  final String displayName;
  final String name;

  OsmPlace({
    required this.placeId,
    required this.lat,
    required this.lon,
    required this.displayName,
    required this.name,
  });

  factory OsmPlace.fromJson(Map<String, dynamic> json) {
    return OsmPlace(
      placeId: json['place_id']?.toString() ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      lon: double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
      displayName: json['display_name']?.toString() ?? '',
      name: json['name']?.toString() ?? json['display_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'lat': lat,
      'lon': lon,
      'display_name': displayName,
      'name': name,
    };
  }
}