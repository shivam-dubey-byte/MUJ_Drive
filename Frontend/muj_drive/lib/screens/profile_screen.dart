import 'package:flutter/material.dart';
import 'package:muj_drive/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.primary,
      ),
      body: Center(
        child: Text(
          'Profile Page',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
