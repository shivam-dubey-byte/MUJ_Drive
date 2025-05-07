// lib/screens/offeredhistory_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:muj_drive/services/token_storage.dart';
import 'package:muj_drive/theme/app_theme.dart';

class OfferedHistoryScreen extends StatefulWidget {
  const OfferedHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OfferedHistoryScreen> createState() => _OfferedHistoryScreenState();
}

class _OfferedHistoryScreenState extends State<OfferedHistoryScreen> {
  static const _baseUrl = 'https://mujdriveride.shivamrajdubey.tech';
  bool _loading = true;

  /// Maps rideId → { rideDetails: {...}, requests: [ {...} ] }
  final Map<String, Map<String, dynamic>> _byRide = {};

  @override
  void initState() {
    super.initState();
    _loadOfferedHistory();
  }

  Future<void> _loadOfferedHistory() async {
    setState(() => _loading = true);
    final token = await TokenStorage.readToken();
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/rides/dashboard'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        // clear & regroup
        _byRide.clear();
        for (var r in (data['incomingRequests'] as List<dynamic>)) {
          final rideId = r['rideId'] as String;
          final rideDetails = r['rideDetails'] as Map<String, dynamic>;
          final requester = r['requester'] as Map<String, dynamic>;
          final entry = _byRide.putIfAbsent(rideId, () => {
                'rideDetails': rideDetails,
                'requests': <Map<String, dynamic>>[],
              });
          entry['requests'].add({
            'bookingId': r['bookingId'],
            'name': requester['name'],
            'registrationNo': requester['registrationNo'],
            'phone': requester['phone'],
            'status': r['status'],
          });
        }
      }
    } catch (_) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildRideSection(String rideId, Map<String, dynamic> ride) {
    final rd = ride['rideDetails'] as Map<String, dynamic>;
    final reqs = ride['requests'] as List<dynamic>;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride header
            Text(
              '${rd['pickupLocation']} → ${rd['dropLocation']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'On ${DateTime.parse(rd['date']).toLocal().toString().split("T").first} at ${rd['time']}',
              style: const TextStyle(color: Colors.black54),
            ),
            const Divider(height: 24),

            // List of requesters
            ...reqs.map<Widget>((r) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['name'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text('Reg#: ${r['registrationNo']}'),
                          Text('Phone: ${r['phone']}'),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(r['status']),
                      backgroundColor: r['status'] == 'accepted'
                          ? Colors.green
                          : r['status'] == 'requested'
                              ? Colors.orange
                              : Colors.grey,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            }).toList(),

            // If no one requested yet:
            if (reqs.isEmpty)
              const Center(
                child: Text(
                  'No one has joined this ride yet.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rideEntries = _byRide.entries.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offered History'),
        backgroundColor: AppTheme.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOfferedHistory,
              child: rideEntries.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            'You haven\'t offered any rides yet.',
                            style: TextStyle(color: Colors.black54, fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: rideEntries.length,
                      itemBuilder: (_, i) {
                        final e = rideEntries[i];
                        return _buildRideSection(e.key, e.value);
                      },
                    ),
            ),
    );
  }
}
