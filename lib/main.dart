import 'package:doc/profileprofile/profile.dart';
import 'package:doc/screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:doc/profileprofile/professional_profile_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Doctor App',
      theme: ThemeData(primarySwatch: Colors.blue),

      // ✅ First screen when app opens
      home: const LoginScreen(),

      // ✅ Named routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/createProfile': (context) => const ProfessionalProfileFormPage(),
        '/doctorProfile': (context) =>
            const DoctorProfilePage(), // works after fix
      },
    );
  }
}
