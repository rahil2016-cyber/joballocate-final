import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../config/api_config.dart';
import '../utils/api_json_decode.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  List<String>? _cachedStates;

  Future<String?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    try {
      final position = await Geolocator.getCurrentPosition();

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Construct a readable address (City, State)
        final city = p.locality ?? p.subAdministrativeArea ?? '';
        final state = p.administrativeArea ?? '';
        if (city.isNotEmpty && state.isNotEmpty) {
          return '$city, $state';
        } else if (city.isNotEmpty) {
          return city;
        } else if (state.isNotEmpty) {
          return state;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<String>> getStates() async {
    if (_cachedStates != null) return _cachedStates!;

    final r = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/locations/states'),
      headers: const {'Accept': 'application/json'},
    );
    final json = decodeApiJsonObject(r);
    // Backend returns: { success: true, data: { states: [...] } }
    final data = json['data'];
    final raw = data is Map && data['states'] is List
        ? data['states']
        : json['states'] is List
        ? json['states']
        : null;
    final states = raw is List
        ? raw
              .map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList()
        : <String>[];

    _cachedStates = states;
    return states;
  }

  Future<List<String>> getDistricts(String state) async {
    final r = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/locations/districts?state=${Uri.encodeComponent(state)}',
      ),
      headers: const {'Accept': 'application/json'},
    );
    final json = decodeApiJsonObject(r);
    // Backend returns: { success: true, data: { districts: [...] } }
    final data = json['data'];
    final raw = data is Map && data['districts'] is List
        ? data['districts']
        : json['districts'] is List
        ? json['districts']
        : null;
    final districts = raw is List
        ? raw
              .map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList()
        : <String>[];
    return districts;
  }
}
