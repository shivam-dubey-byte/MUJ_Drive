import 'package:flutter/material.dart';
import 'package:muj_drive/theme/app_theme.dart';

class BookRideScreen extends StatelessWidget {
  const BookRideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
        backgroundColor: AppTheme.primary,
      ),
      body: Center(
        child: Text(
          'Book a Ride Page',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
