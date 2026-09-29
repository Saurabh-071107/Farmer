import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive status bar matching the ivory theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFCFAF5),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize persistent session state from SharedPreferences
  await SessionManager().init();

  runApp(const PashuFarmerApp());
}

class PashuFarmerApp extends StatelessWidget {
  const PashuFarmerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionManager(),
      builder: (context, _) {
        return MaterialApp(
          key: ValueKey(SessionManager().language),
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppConstants.primaryGreen,
              primary: AppConstants.primaryGreen,
              secondary: AppConstants.accentAmber,
              surface: const Color(0xFFFCFAF5),
            ),
            scaffoldBackgroundColor: const Color(0xFFFCFAF5),
          ),
          home: const AppSessionGate(),
        );
      },
    );
  }
}

class AppSessionGate extends StatefulWidget {
  const AppSessionGate({super.key});

  @override
  State<AppSessionGate> createState() => _AppSessionGateState();
}

class _AppSessionGateState extends State<AppSessionGate> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = SessionManager().init();
  }

  @override
  Widget build(BuildContext context) {
    if (SessionManager().isInitialized) {
      return SessionManager().isLoggedIn
          ? const FarmerHomeScreen()
          : const FarmerLoginScreen();
    }

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done || SessionManager().isInitialized) {
          return SessionManager().isLoggedIn
              ? const FarmerHomeScreen()
              : const FarmerLoginScreen();
        }

        return const Scaffold(
          backgroundColor: Color(0xFFFCFAF5),
          body: Center(
            child: CircularProgressIndicator(
              color: AppConstants.primaryGreen,
            ),
          ),
        );
      },
    );
  }
}
