// lib/screens/book_ride_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:muj_drive/theme/app_theme.dart';

class BookRideScreen extends StatelessWidget {
  const BookRideScreen({Key? key}) : super(key: key);

  // Example data – replace with your real list
  static const List<Map<String, String>> _companies = [
    { 'name': 'Rapid Rides Co.',         'phone': '+911234567890' },
    { 'name': 'Campus Shuttles Pvt. Ltd', 'phone': '+919876543210' },
    { 'name': 'GoDrive Services',        'phone': '+911112223334' },
  ];

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer')),
      );
    }
  }

  void _showDetails(BuildContext context, Map<String, String> company) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                child: Text(
                  company['name']!.substring(0, 1),
                  style: TextStyle(color: AppTheme.primary),
                ),
              ),
              title: Text(
                company['name']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(company['phone']!),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.call),
              label: const Text('Call Now'),
              onPressed: () =>
                  _makePhoneCall(context, company['phone']!),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
        backgroundColor: AppTheme.primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _companies.length,
        itemBuilder: (ctx, i) {
          final company = _companies[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              leading: CircleAvatar(
                backgroundColor: AppTheme.secondary.withOpacity(0.2),
                child: Text(
                  company['name']!.substring(0, 1),
                  style: TextStyle(color: AppTheme.secondary),
                ),
              ),
              title: Text(
                company['name']!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDetails(ctx, company),
            ),
          );
        },
      ),
    );
  }
}
