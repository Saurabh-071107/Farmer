import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pashu_farmer/main.dart';
import 'package:pashu_farmer/screens/home_screen.dart';
import 'package:pashu_farmer/screens/my_animals_screen.dart';

void main() {
  testWidgets('Farmer App Login Screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PashuFarmerApp());

    // Verify Government header and Login button exist
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register as New Farmer'), findsOneWidget);
  });

  testWidgets('Farmer App Home Screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FarmerHomeScreen(),
      ),
    );

    // Verify Welcome header, Weather, Service Grid, and Floating NavBar
    expect(find.textContaining('Welcome'), findsOneWidget);
    expect(find.text('My Livestock'), findsWidgets);
    expect(find.text('Report Sickness'), findsOneWidget);
    expect(find.text('Doctor Call'), findsOneWidget);
    expect(find.text('Vaccination'), findsOneWidget);
    expect(find.text('Marketplace'), findsOneWidget);
    expect(find.text('Govt Schemes'), findsOneWidget);
    expect(find.text('HEALTHY LIVESTOCK\nPROSPEROUS NATION'), findsOneWidget);
  });

  testWidgets('Farmer App My Livestock Screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MyAnimalsScreen()),
      ),
    );

    // Verify Title and Add Livestock button
    expect(find.text('My Livestock'), findsOneWidget);
    expect(find.text('Add Livestock'), findsOneWidget);
    expect(find.textContaining('All'), findsOneWidget);
    expect(find.textContaining('Cow'), findsOneWidget);
    expect(find.textContaining('Buffalo'), findsOneWidget);
    expect(find.textContaining('Goat'), findsOneWidget);
  });
}
