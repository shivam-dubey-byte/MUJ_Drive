// lib/screens/my_rides_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:muj_drive/services/token_storage.dart';
import 'package:muj_drive/theme/app_theme.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({Key? key}) : super(key: key);

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  static const _baseUrl = 'https://mujdriveride.shivamrajdubey.tech';

  bool _loading = true;
  List<dynamic> _incomingRequests = [];
  List<dynamic> _activeBookings   = [];
  List<dynamic> _pendingBookings  = [];
  List<dynamic> _pastBookings     = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
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
        setState(() {
          _incomingRequests = data['incomingRequests'] as List<dynamic>;
          _activeBookings   = data['activeBookings']   as List<dynamic>;
          _pendingBookings  = data['pendingBookings']  as List<dynamic>;
          _pastBookings     = data['pastBookings']     as List<dynamic>;
        });
      }
    } catch (_) {
      // optionally show an error
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _respondToRequest(
      String rideId, String bookingId, bool accept) async {
    final token = await TokenStorage.readToken();
    if (token == null) return;
    final action = accept ? 'accept' : 'reject';
    await http.put(
      Uri.parse('$_baseUrl/rides/$rideId/requests/$bookingId/$action'),
      headers: {'Authorization': 'Bearer $token'},
    );
    await _loadDashboard();
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      );

  Widget _buildIncomingCard(dynamic r) {
    final rd = r['rideDetails'] as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Requester: ${r['requester']['name']}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Reg. No.: ${r['requester']['registrationNo']}'),
          Text('Phone: ${r['requester']['phone']}'),
          const Divider(height: 24),
          Text('Route: ${rd['pickupLocation']} → ${rd['dropLocation']}'),
          const SizedBox(height: 4),
          Text(
            'When: ${DateTime.parse(rd['date']).toLocal().toString().split(' ')[0]}'
            ' at ${rd['time']}',
          ),
          const SizedBox(height: 16),
          // Beautiful row of buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _respondToRequest(r['rideId'], r['bookingId'], true),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _respondToRequest(r['rideId'], r['bookingId'], false),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildBookingCard(dynamic b) {
    final rd = b['rideDetails'] as Map<String, dynamic>;
    final user = b.containsKey('offerer') ? b['offerer'] : b['requester'];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
            '${b.containsKey('offerer') ? 'Offerer' : 'Requester'}: ${user['name']}'),
        subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reg. No.: ${user['registrationNo']}'),
              Text('Phone: ${user['phone']}'),
              const SizedBox(height: 8),
              Text('Route: ${rd['pickupLocation']} → ${rd['dropLocation']}'),
              Text(
                'When: ${DateTime.parse(rd['date']).toLocal().toString().split(' ')[0]}'
                ' at ${rd['time']}',
              ),
            ]),
        isThreeLine: true,
        trailing: Chip(
          label:
              Text(b['status'], style: const TextStyle(color: Colors.white)),
          backgroundColor: b['status'] == 'accepted'
              ? Colors.green
              : b['status'] == 'requested'
                  ? Colors.orange
                  : Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rides'),
        backgroundColor: AppTheme.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_incomingRequests.isNotEmpty) ...[
                    _sectionHeader('Incoming Requests'),
                    ..._incomingRequests.map(_buildIncomingCard),
                  ],
                  if (_activeBookings.isNotEmpty) ...[
                    _sectionHeader('Active Bookings'),
                    ..._activeBookings.map(_buildBookingCard),
                  ],
                  if (_pendingBookings.isNotEmpty) ...[
                    _sectionHeader('Pending Bookings'),
                    ..._pendingBookings.map(_buildBookingCard),
                  ],
                  if (_pastBookings.isNotEmpty) ...[
                    _sectionHeader('Past Bookings'),
                    ..._pastBookings.map(_buildBookingCard),
                  ],
                  if (_incomingRequests.isEmpty &&
                      _activeBookings.isEmpty &&
                      _pendingBookings.isEmpty &&
                      _pastBookings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No rides or requests found.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
