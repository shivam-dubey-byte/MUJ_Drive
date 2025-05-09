import 'package:flutter/material.dart';
import 'package:muj_drive/theme/app_theme.dart';
import 'package:muj_drive/services/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverUnderDevelopmentScreen extends StatelessWidget {
  const DriverUnderDevelopmentScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    // Clear stored token and user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await TokenStorage.clearToken();

    // Navigate directly to the initial screen, removing all previous routes
    //Navigator.pushNamedAndRemoveUntil(context, '/initial', (route) => true);
      // Navigate directly to the initial screen, removing all previous routes
  Navigator.of(context).pushNamedAndRemoveUntil('/initial', (route) =>false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Area'),
        backgroundColor: AppTheme.primary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.build_circle, size: 80, color: AppTheme.primary),
              const SizedBox(height: 24),
              Text(
                '🚧 Driver Side is Under Development 🚧',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
