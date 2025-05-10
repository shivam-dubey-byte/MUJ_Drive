// lib/screens/book_ride_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:muj_drive/theme/app_theme.dart';
import 'package:muj_drive/services/token_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class BookRideScreen extends StatefulWidget {
  const BookRideScreen({Key? key}) : super(key: key);

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  static const String _baseUrl = 'https://mujdriveride.shivamrajdubey.tech';
  List<Map<String, String>> _companies = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = await TokenStorage.readToken() ?? '';
      final res = await http.get(
        Uri.parse('$_baseUrl/api/drivers'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> raw = jsonDecode(res.body);
        setState(() {
          _companies = raw.map<Map<String, String>>((item) {
            return {
              'name': item['name'] as String,
              'phone': item['phone'] as String,
            };
          }).toList();
          _loading = false;
        });
      } else if (res.statusCode == 401) {
        setState(() {
          _errorMessage = 'Unauthorized: please log in again.';
          _loading = false;
        });
      } else if (res.statusCode == 403) {
        setState(() {
          _errorMessage = 'Access denied: students only.';
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load drivers (${res.statusCode}).';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching drivers:\n$e';
        _loading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer')),
      );
    }
  }

  void _showDetails(Map<String, String> company) {
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
              onPressed: () => _makePhoneCall(company['phone']!),
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
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDrivers),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _companies.length,
                  itemBuilder: (_, i) {
                    final company = _companies[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.secondary.withOpacity(0.2),
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
                        onTap: () => _showDetails(company),
                      ),
                    );
                  },
                ),
    );
  }
}
