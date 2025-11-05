import 'package:doc/profileprofile/professional_profile_page.dart';
import 'package:doc/screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:doc/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Surgeon Search',
      theme: ThemeData(primarySwatch: Colors.blue),

      // ✅ Initial route
      initialRoute: '/',

      // ✅ Routes table
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/profile': (context) => const ProfessionalProfileFormPage(),
      },
    );
  }
}
