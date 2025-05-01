import 'package:flutter/material.dart';
import 'package:muj_drive/theme/app_theme.dart';

class OfferRideScreen extends StatelessWidget {
  const OfferRideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offer Ride'),
        backgroundColor: AppTheme.primary,
      ),
      body: Center(
        child: Text(
          'Offer Ride Page',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
