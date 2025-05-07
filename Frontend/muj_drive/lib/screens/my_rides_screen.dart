// lib/screens/my_rides_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:muj_drive/services/token_storage.dart';
import 'package:muj_drive/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({Key? key}) : super(key: key);

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  static const _baseUrl = 'https://mujdriveride.shivamrajdubey.tech';

  bool _loading = true;
  List<dynamic> _incomingRequests = [];
  List<dynamic> _activeBookings = [];
  List<dynamic> _pendingBookings = [];
  List<dynamic> _pastBookings = [];

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
        var inReq = data['incomingRequests'] as List<dynamic>;
        var actB = data['activeBookings'] as List<dynamic>;
        var penB = data['pendingBookings'] as List<dynamic>;
        var pastB = data['pastBookings'] as List<dynamic>;

        DateTime extractDt(Map<String, dynamic> b) {
          final rd = b['rideDetails'] as Map<String, dynamic>;
          final date = DateTime.parse(rd['date'] as String);
          final parts = (rd['time'] as String).split(' ');
          final hm = parts[0].split(':').map(int.parse).toList();
          var h = hm[0], m = hm[1];
          if (parts.length == 2) {
            final ap = parts[1].toLowerCase();
            if (ap == 'pm' && h < 12) h += 12;
            if (ap == 'am' && h == 12) h = 0;
          }
          return DateTime(date.year, date.month, date.day, h, m);
        }

        inReq.sort((a, b) => extractDt(b).compareTo(extractDt(a)));
        actB.sort((a, b) => extractDt(b).compareTo(extractDt(a)));
        penB.sort((a, b) => extractDt(b).compareTo(extractDt(a)));
        pastB.sort((a, b) => extractDt(b).compareTo(extractDt(a)));

        setState(() {
          _incomingRequests = inReq;
          _activeBookings = actB;
          _pendingBookings = penB;
          _pastBookings = pastB;
        });
      }
    } catch (_) {
      // ignore
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

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      );

  Widget _buildCallButton(String phone) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _makePhoneCall(phone),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.call, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Call',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingCard(dynamic r) {
    final rd = r['rideDetails'] as Map<String, dynamic>;
    final name = r['requester']['name'] as String;
    final phone = r['requester']['phone'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.person, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            const Icon(Icons.phone, color: Colors.black54),
            const SizedBox(width: 4),
            Text(phone, style: const TextStyle(color: Colors.black54)),
          ]),
          const Divider(height: 24),
          Row(children: [
            const Icon(Icons.alt_route, color: Colors.black54),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${rd['pickupLocation']} → ${rd['dropLocation']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
            const SizedBox(width: 4),
            Text(DateTime.parse(rd['date'])
                .toLocal()
                .toString()
                .split(' ')[0]),
            const SizedBox(width: 16),
            const Icon(Icons.access_time, size: 16, color: Colors.black54),
            const SizedBox(width: 4),
            Text(rd['time']),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _respondToRequest(r['rideId'], r['bookingId'], true),
                icon: const Icon(Icons.check),
                label: const Text('Accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _respondToRequest(r['rideId'], r['bookingId'], false),
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildCallButton(phone),
          ),
        ]),
      ),
    );
  }

  Widget _buildBookingCard(dynamic b) {
    final rd = b['rideDetails'] as Map<String, dynamic>;
    final user = b.containsKey('offerer') ? b['offerer'] : b['requester'];
    final name = user['name'] as String;
    final phone = user['phone'] as String;
    final status = b['status'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.person, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            const Icon(Icons.phone, color: Colors.black54),
            const SizedBox(width: 4),
            Text(phone, style: const TextStyle(color: Colors.black54)),
          ]),
          const Divider(height: 24),
          Row(children: [
            const Icon(Icons.alt_route, color: Colors.black54),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${rd['pickupLocation']} → ${rd['dropLocation']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
            const SizedBox(width: 4),
            Text(DateTime.parse(rd['date'])
                .toLocal()
                .toString()
                .split(' ')[0]),
            const SizedBox(width: 16),
            const Icon(Icons.access_time, size: 16, color: Colors.black54),
            const SizedBox(width: 4),
            Text(rd['time']),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _buildCallButton(phone),
            const Spacer(),
            Chip(
              label: Text(status, style: const TextStyle(color: Colors.white)),
              backgroundColor: status == 'accepted'
                  ? Colors.green
                  : status == 'requested'
                      ? Colors.orange
                      : Colors.grey,
            ),
          ]),
        ]),
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
