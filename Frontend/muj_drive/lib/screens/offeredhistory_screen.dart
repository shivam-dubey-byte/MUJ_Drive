// lib/screens/offeredhistory_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:muj_drive/services/token_storage.dart';
import 'package:muj_drive/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class OfferedhistoryScreen extends StatefulWidget {
  const OfferedhistoryScreen({Key? key}) : super(key: key);

  @override
  State<OfferedhistoryScreen> createState() => _OfferedhistoryScreenState();
}

class _OfferedhistoryScreenState extends State<OfferedhistoryScreen> {
  static const _baseUrl = 'https://mujdriveride.shivamrajdubey.tech';
  bool _loading = true;
  List<dynamic> _rides = [];

  @override
  void initState() {
    super.initState();
    _fetchOfferedHistory();
  }

  Future<void> _fetchOfferedHistory() async {
    setState(() => _loading = true);
    final token = await TokenStorage.readToken();
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/rides/offered-history'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['offeredRides'] as List<dynamic>;
        list.sort((a, b) {
          final da = DateTime.parse(a['date'] as String);
          final db = DateTime.parse(b['date'] as String);
          return db.compareTo(da);
        });
        setState(() => _rides = list);
      }
    } catch (_) {
      // ignore errors
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot launch phone dialer')),
      );
    }
  }

  Widget _buildCallButton(String phone) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _makePhoneCall(phone),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Icon(Icons.call, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    final pickup = ride['pickupLocation'] ?? '-';
    final drop = ride['dropLocation'] ?? '-';
    final dateStr = ride['date'] != null
        ? DateTime.parse(ride['date'])
            .toLocal()
            .toString()
            .split(' ')[0]
        : '-';
    final time = ride['time'] ?? '-';
    final total = ride['totalSeats']?.toString() ?? '-';
    final avail = ride['seatsAvailable']?.toString() ?? '-';
    final joiners = ride['joiners'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride summary
            Row(
              children: [
                const Icon(Icons.local_taxi, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$pickup → $drop',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('When: $dateStr at $time'),
            const SizedBox(height: 4),
            Text('Seats: $avail / $total'),
            const Divider(height: 24),

            // Joined Riders Header
            const Text(
              'Joined Riders',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // If no joiners
            if (joiners.isEmpty)
              Text(
                'No one has joined yet.',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              // Use ListTile for each joiner for clarity
              ...joiners.map<Widget>((j) {
                final student = j['student'] as Map<String, dynamic>? ?? {};
                final name = student['name'] ?? 'Unknown';
                final phone = student['phone'] ?? '-';
                final status = (j['status'] ?? '').toString();

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: const Icon(Icons.person, color: AppTheme.primary),
                    title: Text(name, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(phone, style: const TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCallButton(phone),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: status == 'accepted'
                              ? Colors.green
                              : status == 'requested'
                                  ? Colors.orange
                                  : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offered History'),
        backgroundColor: AppTheme.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchOfferedHistory,
              child: _rides.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 200),
                        Center(
                          child: Text(
                            'You haven’t offered any rides yet.',
                            style:
                                TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _rides.length,
                      itemBuilder: (_, i) =>
                          _buildRideCard(_rides[i] as Map<String, dynamic>),
                    ),
            ),
    );
  }
}
