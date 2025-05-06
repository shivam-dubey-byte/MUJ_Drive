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
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _myBookings       = [];

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    final token = await TokenStorage.readToken();
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // 1) Incoming requests for rides I offered
      final reqRes = await http.get(
        Uri.parse('$_baseUrl/rides/requests'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (reqRes.statusCode == 200) {
        final body = jsonDecode(reqRes.body) as Map<String, dynamic>? ?? {};
        final list = (body['requests'] as List<dynamic>?) ?? [];
        _incomingRequests = list.cast<Map<String, dynamic>>();
      } else {
        _incomingRequests = [];
      }

      // 2) My bookings (as a rider)
      final bookRes = await http.get(
        Uri.parse('$_baseUrl/rides/bookings'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (bookRes.statusCode == 200) {
        final body = jsonDecode(bookRes.body) as Map<String, dynamic>? ?? {};
        final list = (body['bookings'] as List<dynamic>?) ?? [];
        _myBookings = list.cast<Map<String, dynamic>>();
      } else {
        _myBookings = [];
      }
    } catch (_) {
      _incomingRequests = [];
      _myBookings       = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleRequest(
      String rideId, String bookingId, bool accept) async {
    final token = await TokenStorage.readToken();
    if (token == null) return;

    final action = accept ? 'accept' : 'reject';
    await http.put(
      Uri.parse('$_baseUrl/rides/$rideId/requests/$bookingId/$action'),
      headers: {'Authorization': 'Bearer $token'},
    );
    await _fetchAll();
  }

  Widget _buildRequestsSection() {
    if (_incomingRequests.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Incoming Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ..._incomingRequests.map((r) {
          final rideDetails = (r['rideDetails'] as Map<String, dynamic>?) ?? {};
          final pickup    = rideDetails['pickupLocation'] as String? ?? 'N/A';
          final drop      = rideDetails['dropLocation']   as String? ?? 'N/A';
          final date      = rideDetails['date']?.split("T").first ?? '';
          final time      = rideDetails['time']           as String? ?? '';
          final studentEmail = r['studentEmail']       as String? ?? 'Unknown';
          final bookingId    = r['_id']                as String? ?? '';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text(studentEmail),
              subtitle: Text(
                '$pickup → $drop\non $date at $time',
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: bookingId.isEmpty
                        ? null
                        : () => _handleRequest(r['rideId'] as String, bookingId, true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: bookingId.isEmpty
                        ? null
                        : () => _handleRequest(r['rideId'] as String, bookingId, false),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMyBookingsSection() {
    if (_myBookings.isEmpty) return const SizedBox();

    final active  = _myBookings.where((b) => b['status'] == 'accepted').toList();
    final pending = _myBookings.where((b) => b['status'] == 'requested').toList();
    final past    = _myBookings.where((b) {
      final s = b['status'] as String?;
      return s != 'accepted' && s != 'requested';
    }).toList();

    final sections = <Widget>[];

    void addSection(String title, List<Map<String, dynamic>> list) {
      if (list.isEmpty) return;
      sections.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      );
      sections.addAll(list.map((b) {
        final rideId   = b['rideId']   as String? ?? '—';
        final status   = b['status']   as String? ?? '—';
        final bookingId = b['bookingId'] as String? ?? b['_id'] as String? ?? '';
        return ListTile(
          title: Text('Ride $rideId'),
          subtitle: Text('Status: $status\nBooking: $bookingId'),
          isThreeLine: true,
        );
      }));
    }

    addSection('Active Rides', active);
    addSection('Pending Requests', pending);
    addSection('Past Rides', past);

    return Column(children: sections);
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
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequestsSection(),
                  _buildMyBookingsSection(),
                ],
              ),
            ),
    );
  }
}
