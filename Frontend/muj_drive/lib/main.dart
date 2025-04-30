// lib/main.dart

import 'package:flutter/material.dart';
import 'package:muj_drive/theme/app_theme.dart';
import 'package:muj_drive/screens/initial_screen.dart';
import 'package:muj_drive/screens/login_screen.dart';
import 'package:muj_drive/screens/home_screen.dart';
import 'package:muj_drive/screens/otp_verification.dart';

void main() => runApp(const MUJDriveApp());

class MUJDriveApp extends StatelessWidget {
  const MUJDriveApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MUJ Drive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/':     (_) => const InitialScreen(),
        '/home': (_) => const HomeScreen(),
        // static '/otp' removed
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            final userType = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => LoginScreen(userType: userType),
            );

          case '/otp':
            final email = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(email: email),
            );

          default:
            return null;
        }
      },
    );
  }
}
