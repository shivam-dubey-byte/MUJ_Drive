// lib/screens/find_ride_results_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:muj_drive/services/token_storage.dart';
import 'package:muj_drive/theme/app_theme.dart';

class FindRideResultsScreen extends StatefulWidget {
  final String pickup, drop;
  final DateTime date;
  final TimeOfDay time;
  final List<Map<String, dynamic>> rides;

  const FindRideResultsScreen({
    Key? key,
    required this.pickup,
    required this.drop,
    required this.date,
    required this.time,
    required this.rides,
  }) : super(key: key);

  @override
  _FindRideResultsScreenState createState() => _FindRideResultsScreenState();
}

class _FindRideResultsScreenState extends State<FindRideResultsScreen> {
  static const _baseUrl = 'https://mujdriveride.shivamrajdubey.tech';
  final Map<int, String> _pendingRequests = {};

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    final token = await TokenStorage.readToken();
    if (token == null) return;
    final res = await http.get(
      Uri.parse('$_baseUrl/rides/bookings'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final List<dynamic> bookings = body['bookings'] ?? [];
      setState(() {
        _pendingRequests.clear();
        for (var b in bookings) {
          if (b['status'] == 'requested') {
            final rideId = b['rideId'] as String;
            final bookingId = b['bookingId'].toString();
            final idx =
                widget.rides.indexWhere((r) => r['rideId'] == rideId);
            if (idx >= 0) _pendingRequests[idx] = bookingId;
          }
        }
      });
    }
  }

  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yy = dt.year.toString();
    return '$dd/$mm/$yy';
  }

  Future<void> _launchCaller(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot launch dialer')),
      );
    }
  }

  Future<void> _bookRide(int index) async {
    final rideId = widget.rides[index]['rideId'] as String;
    final token = await TokenStorage.readToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required')),
      );
      return;
    }
    final res = await http.post(
      Uri.parse('$_baseUrl/rides/$rideId/request'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final bookingId = body['bookingId']?.toString();
      if (bookingId != null) {
        setState(() => _pendingRequests[index] = bookingId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride requested')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed (${res.statusCode})')),
      );
    }
  }

  Future<void> _cancelRide(int index) async {
    final rideId = widget.rides[index]['rideId'] as String;
    final bookingId = _pendingRequests[index];
    if (bookingId == null) return;
    final token = await TokenStorage.readToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required')),
      );
      return;
    }
    final res = await http.put(
      Uri.parse('$_baseUrl/rides/$rideId/requests/$bookingId/cancel'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      setState(() => _pendingRequests.remove(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cancelled')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancel failed (${res.statusCode})')),
      );
    }
  }

  /// Safely extracts “HH:mm” from strings like "08:30 AM" or "20:15"
  TimeOfDay _parseTime(String raw) {
    final match = RegExp(r'(\d{1,2}):(\d{1,2})').firstMatch(raw);
    if (match != null) {
      final h = int.parse(match.group(1)!);
      final m = int.parse(match.group(2)!);
      return TimeOfDay(hour: h, minute: m);
    }
    return const TimeOfDay(hour: 0, minute: 0);
  }

  Widget _buildRideCard(
      BuildContext context, Map<String, dynamic> ride, int index) {
    final isRequested = _pendingRequests.containsKey(index);

    final riderName = ride['name'] as String;
    final phoneNumber = ride['phone'] as String;
    final dt = DateTime.parse(ride['date'].toString());
    final dateStr = _formatDate(dt);
    final timeStr = _parseTime(ride['time'] as String).format(context);
    final seats = ride['seatsAvailable'];
    final luggage = ride['luggage'] as Map<String, dynamic>;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(riderName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Text(dateStr, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 24),
              const Icon(Icons.access_time, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Text(timeStr, style: const TextStyle(fontSize: 14)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.event_seat, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Text('Seats: $seats', style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 24),
              const Icon(Icons.work, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                'S:${luggage['small']} M:${luggage['medium']} L:${luggage['large']}',
                style: const TextStyle(fontSize: 14),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchCaller(phoneNumber),
                  icon: const Icon(Icons.call, color: AppTheme.primary),
                  label: const Text('Call',
                      style: TextStyle(color: AppTheme.primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      isRequested ? _cancelRide(index) : _bookRide(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isRequested ? Colors.grey : AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    isRequested ? 'Cancel Request' : 'Book Ride',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rides'),
        backgroundColor: AppTheme.primary,
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Row(children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 12, color: AppTheme.primary),
                Container(width: 2, height: 36, color: Colors.grey.shade300),
                const Icon(Icons.location_on, size: 16, color: Colors.red),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.pickup,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(widget.drop,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today, size: 20, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(_formatDate(widget.date),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(width: 24),
            const Icon(Icons.access_time, size: 20, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(widget.time.format(context),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ]),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: widget.rides.isEmpty
              ? const Center(child: Text('No rides found'))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: widget.rides.length,
                  itemBuilder: (_, i) =>
                      _buildRideCard(context, widget.rides[i], i),
                ),
        ),
      ]),
    );
  }
}
