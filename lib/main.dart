import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zoodo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF0C831F), // Zoodo Green
        scaffoldBackgroundColor: const Color(0xFFF3F4F6), // Light grey
        cardColor: const Color(0xFFFFFFFF), // White cards
        
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0C831F), // Brand Green
          secondary: Color(0xFFF7D108), // Brand Yellow
          secondaryContainer: Color(0xFF0C831F),
          surface: Color(0xFFFFFFFF),
          error: Color(0xFFEF4444),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.black,
        ),
        
        textTheme: const TextTheme(
          displayMedium: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.4,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
