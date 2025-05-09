import 'package:flutter/material.dart';
import 'package:muj_drive/theme/app_theme.dart';

class DriverUnderDevelopmentScreen extends StatelessWidget {
  const DriverUnderDevelopmentScreen({Key? key}) : super(key: key);

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
                onPressed: () => Navigator.pushReplacementNamed(context, '/initial'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Return to Welcome'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
