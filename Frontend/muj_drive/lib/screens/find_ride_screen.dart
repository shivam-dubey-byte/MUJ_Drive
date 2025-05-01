import 'package:flutter/material.dart';
import 'package:muj_drive/theme/app_theme.dart';

class FindRideScreen extends StatelessWidget {
  const FindRideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Ride'),
        backgroundColor: AppTheme.primary,
      ),
      body: Center(
        child: Text(
          'Find Ride Page',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
