import 'package:flutter/material.dart';
import 'package:muj_drive/theme/app_theme.dart';

class MyRidesScreen extends StatelessWidget {
  const MyRidesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rides'),
        backgroundColor: AppTheme.primary,
      ),
      body: Center(
        child: Text(
          'My Rides Page',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
