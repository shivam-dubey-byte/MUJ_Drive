// lib/main.dart

import 'package:flutter/material.dart';
import 'package:muj_drive/theme/app_theme.dart';
import 'package:muj_drive/screens/initial_screen.dart';
import 'package:muj_drive/screens/login_screen.dart';
import 'package:muj_drive/screens/otp_verification.dart';
import 'package:muj_drive/screens/home_screen.dart';
import 'package:muj_drive/screens/book_ride_screen.dart';
import 'package:muj_drive/screens/find_ride_screen.dart';
import 'package:muj_drive/screens/offer_ride_screen.dart';
import 'package:muj_drive/screens/my_rides_screen.dart';
import 'package:muj_drive/screens/profile_screen.dart';
import 'package:muj_drive/screens/notification_screen.dart'; // ✅ added
import 'package:muj_drive/screens/offeredhistory_screen.dart';

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
        '/':           (_) => const InitialScreen(),
        '/home':       (_) => const HomeScreen(),
        '/book-ride':  (_) => const BookRideScreen(),
        '/find-ride':  (_) => const FindRideScreen(),
        '/offer-ride': (_) => const OfferRideScreen(),
        '/my-rides':   (_) => const MyRidesScreen(),
        '/profile':    (_) => const ProfileScreen(),
        '/notifications': (_) => const NotificationScreen(), // ✅ added route
        '/offered-history': (_) => const OfferedhistoryScreen(),
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
