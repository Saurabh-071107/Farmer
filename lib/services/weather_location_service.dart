import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class FarmerWeatherResult {
  final String city;
  final String state;
  final String temp;
  final String condition;
  final double latitude;
  final double longitude;
  final bool isLiveGps;

  FarmerWeatherResult({
    required this.city,
    required this.state,
    required this.temp,
    required this.condition,
    required this.latitude,
    required this.longitude,
    required this.isLiveGps,
  });

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'state': state,
      'temp': temp,
      'condition': condition,
      'latitude': latitude,
      'longitude': longitude,
      'isLiveGps': isLiveGps,
    };
  }
}

class WeatherLocationService {
  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: '',
  );

  // Default fallback coordinates (Pune, Maharashtra)
  static const double defaultLat = 18.5204;
  static const double defaultLon = 73.8567;

  /// Requests device GPS permission and fetches current position
  Future<Position?> getCurrentGpsPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled by user.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions denied by user.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions permanently denied.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
    } catch (e) {
      debugPrint('Error getting GPS position: $e');
      return null;
    }
  }

  /// Fetches real weather and location name
  Future<FarmerWeatherResult> getFarmerWeatherAndLocation({
    String? fallbackCity,
    String? fallbackState,
  }) async {
    Position? position = await getCurrentGpsPosition();
    final bool isLiveGps = position != null;
    final double lat = position?.latitude ?? defaultLat;
    final double lon = position?.longitude ?? defaultLon;

    // 1. Primary Attempt: OpenWeather API (Using configured API key if available)
    if (openWeatherApiKey.isNotEmpty) {
      try {
        final openWeatherUrl = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$openWeatherApiKey',
        );
        final response = await http.get(openWeatherUrl).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final cityName = data['name']?.toString().isNotEmpty == true
              ? data['name'].toString()
              : (fallbackCity ?? 'Pune');
          final temp = '${(data['main']['temp'] as num).round()}°C';
          final condition = data['weather']?[0]?['main']?.toString() ?? 'Clear Sky';

          return FarmerWeatherResult(
            city: cityName,
            state: fallbackState ?? 'Maharashtra',
            temp: temp,
            condition: condition,
            latitude: lat,
            longitude: lon,
            isLiveGps: isLiveGps,
          );
        }
      } catch (e) {
        debugPrint('OpenWeather API attempt error or key pending activation: $e');
      }
    }

    // 2. High-Precision Real-Time Fallback: Open-Meteo + Reverse Geocoding
    // Ensures real weather is ALWAYS available even while the OpenWeather key is activating on their servers
    try {
      final meteoUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true',
      );
      final meteoRes = await http.get(meteoUrl).timeout(const Duration(seconds: 4));

      if (meteoRes.statusCode == 200) {
        final meteoData = jsonDecode(meteoRes.body);
        final currentWeather = meteoData['current_weather'];
        final double rawTemp = (currentWeather['temperature'] as num).toDouble();
        final int weatherCode = (currentWeather['weathercode'] as num).toInt();
        final String conditionDesc = _mapWeatherCode(weatherCode);

        // Fetch location name via Reverse Geocoding
        String resolvedCity = fallbackCity ?? 'Pune';
        String resolvedState = fallbackState ?? 'Maharashtra';

        try {
          final geoUrl = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json',
          );
          final geoRes = await http.get(geoUrl, headers: {'User-Agent': 'PashuSeva/1.0'})
              .timeout(const Duration(seconds: 3));
          if (geoRes.statusCode == 200) {
            final geoData = jsonDecode(geoRes.body);
            final address = geoData['address'];
            resolvedCity = address['city'] ?? address['town'] ?? address['county'] ?? address['state_district'] ?? resolvedCity;
            resolvedState = address['state'] ?? resolvedState;
          }
        } catch (_) {}

        return FarmerWeatherResult(
          city: resolvedCity,
          state: resolvedState,
          temp: '${rawTemp.round()}°C',
          condition: conditionDesc,
          latitude: lat,
          longitude: lon,
          isLiveGps: isLiveGps,
        );
      }
    } catch (e) {
      debugPrint('Open-Meteo fallback error: $e');
    }

    // 3. Resilient Offline Default
    return FarmerWeatherResult(
      city: fallbackCity ?? 'Pune',
      state: fallbackState ?? 'Maharashtra',
      temp: '26°C',
      condition: 'Clear Sky',
      latitude: lat,
      longitude: lon,
      isLiveGps: false,
    );
  }

  String _mapWeatherCode(int code) {
    if (code == 0) return 'Clear Sky';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 48) return 'Hazy / Fog';
    if (code <= 55) return 'Drizzle';
    if (code <= 67) return 'Rain Showers';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Heavy Rain';
    if (code <= 99) return 'Thunderstorm';
    return 'Clear Sky';
  }
}
