import 'package:flutter_test/flutter_test.dart';
import 'package:pashu_farmer/services/weather_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('WeatherLocationService fallback test', () async {
    final service = WeatherLocationService();
    final result = await service.getFarmerWeatherAndLocation(
      fallbackCity: 'Pune',
      fallbackState: 'Maharashtra',
    );

    expect(result.city, isNotEmpty);
    expect(result.temp, contains('°C'));
    expect(result.condition, isNotEmpty);
  });
}
