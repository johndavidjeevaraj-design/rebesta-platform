class Address {
  final String id;
  final String title;
  final String address;
  final double latitude;
  final double longitude;

  const Address({
    required this.id,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Address',
      address: json['address']?.toString() ?? '',
      latitude: double.tryParse(
            json['latitude']?.toString() ?? '',
          ) ??
          0.0,
      longitude: double.tryParse(
            json['longitude']?.toString() ?? '',
          ) ??
          0.0,
    );
  }
}