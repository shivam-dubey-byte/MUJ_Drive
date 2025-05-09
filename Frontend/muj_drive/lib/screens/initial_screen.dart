import 'package:flutter/material.dart';
import 'package:muj_drive/services/token_storage.dart';
import 'package:muj_drive/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({Key? key}) : super(key: key);

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkJwt();
  }

  Future<void> _checkJwt() async {
    final token = await TokenStorage.readToken();
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    // Delay navigation until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
            if (role == 'Driver') {
        // Always redirect drivers to the under development screen
        Navigator.pushReplacementNamed(context, '/driver-development');
      } else if (token != null && token.isNotEmpty && role == 'Student') {
        print('🚦 InitialScreen: token exists, navigating to /home');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        print('🚦 InitialScreen: no token, showing welcome UI');
        setState(() => _checking = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 12,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome To MUJ Drive',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.school, color: Colors.white),
                    label: const Text('I am a Student'),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/login',
                      arguments: 'Student',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.drive_eta, color: Colors.white,),
                    label: const Text('I am a Driver'),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/login',
                      arguments: 'Driver',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
