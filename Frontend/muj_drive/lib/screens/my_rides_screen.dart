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
      } else {
        // handle error...
      }
    } catch (e) {
      // handle network error...
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _respondToRequest(String rideId, String bookingId, bool accept) async {
    final token = await TokenStorage.readToken();
    if (token == null) return;
    final action = accept ? 'accept' : 'reject';
    await http.put(
      Uri.parse('$_baseUrl/rides/$rideId/requests/$bookingId/$action'),
      headers: {'Authorization': 'Bearer $token'},
    );
    await _loadDashboard();
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildIncomingCard(dynamic r) {
    final rd = r['rideDetails'] as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Requester: ${r['requester']['name']}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text('Reg. No.: ${r['requester']['registrationNo']}'),
          Text('Phone: ${r['requester']['phone']}'),
          const SizedBox(height: 8),
          Text('Route: ${rd['pickupLocation']} → ${rd['dropLocation']}'),
          Text('When: ${DateTime.parse(rd['date']).toLocal().toString().split(' ')[0]} at ${rd['time']}'),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => _respondToRequest(r['rideId'], r['bookingId'], true),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => _respondToRequest(r['rideId'], r['bookingId'], false),
            ),
          ]),
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
        title: Text('${b.containsKey('offerer') ? 'Offerer' : 'Requester'}: ${user['name']}'),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Reg. No.: ${user['registrationNo']}'),
          Text('Phone: ${user['phone']}'),
          const SizedBox(height: 4),
          Text('Route: ${rd['pickupLocation']} → ${rd['dropLocation']}'),
          Text('When: ${DateTime.parse(rd['date']).toLocal().toString().split(' ')[0]} at ${rd['time']}'),
        ]),
        isThreeLine: true,
        trailing: Chip(
          label: Text(b['status'], style: const TextStyle(color: Colors.white)),
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
