class LocationAlarm {
  const LocationAlarm({
    required this.id,
    required this.label,
    required this.lat,
    required this.lng,
    this.radiusMeters = 200,
    this.isEnabled = true,
  });

  final String id;
  final String label;
  final double lat;
  final double lng;
  final double radiusMeters;
  final bool isEnabled;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'lat': lat,
    'lng': lng,
    'radiusMeters': radiusMeters,
    'isEnabled': isEnabled,
  };

  factory LocationAlarm.fromJson(Map<String, dynamic> json) => LocationAlarm(
    id: json['id'] as String? ?? '',
    label: json['label'] as String? ?? '',
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lng: (json['lng'] as num?)?.toDouble() ?? 0,
    radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 200,
    isEnabled: json['isEnabled'] as bool? ?? true,
  );

  LocationAlarm copyWith({
    String? id,
    String? label,
    double? lat,
    double? lng,
    double? radiusMeters,
    bool? isEnabled,
  }) {
    return LocationAlarm(
      id: id ?? this.id,
      label: label ?? this.label,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
