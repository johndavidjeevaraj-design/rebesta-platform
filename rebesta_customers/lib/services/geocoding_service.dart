import 'package:geocoding/geocoding.dart';

class GeocodingService {
  Future<String> getAddress(
    double latitude,
    double longitude,
  ) async {
    List<Placemark> places = await placemarkFromCoordinates(
      latitude,
      longitude,
    );

    if (places.isEmpty) {
      return "Unknown Location";
    }

    final p = places.first;

    return [
      p.name,
      p.street,
      p.locality,
      p.administrativeArea,
    ].where((e) => e != null && e.isNotEmpty).join(", ");
  }
}