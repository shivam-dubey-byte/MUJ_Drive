import 'package:flutter/material.dart';
import 'package:muj_drive/theme/app_theme.dart';
import 'package:muj_drive/screens/initial_screen.dart';
import 'package:muj_drive/screens/login_screen.dart';
import 'package:muj_drive/screens/otp_verification.dart';

void main() {
  runApp(const MUJDriveApp());
}

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
        '/': (_) => const InitialScreen(),
        '/otp': (_) => const OtpVerificationScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/login') {
          final userType = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => LoginScreen(userType: userType),
          );
        }
        return null;
      },
    );
  }
}
