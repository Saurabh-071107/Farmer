import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Pashu Seva - Farmer';

  // Android emulator uses 10.0.2.2 to access host machine localhost:5000
  // For web or physical device on LAN, change to your local IP or backend URL
  static const String apiBaseUrl = 'http://10.0.2.2:5000/api';

  // App Theme Colors (Earthy Green & Warm Harvest Amber)
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color secondaryGreen = Color(0xFF2E7D32);
  static const Color accentAmber = Color(0xFFFF8F00);
  static const Color backgroundLight = Color(0xFFF9FBE7);
  static const Color cardBg = Colors.white;
  static const Color dangerRed = Color(0xFFC62828);
}
