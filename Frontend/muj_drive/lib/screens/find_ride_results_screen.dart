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
  // Base URL of your backend
  static const _baseUrl = 'https://mujdriveride.shivamrajdubey.tech';

  // Tracks which ride indexes have an active request
  final Set<int> _requestedIndices = {};
  // Maps index to bookingId so we can cancel
  final Map<int, String> _bookingIds = {};

  @override
  void initState() {
    super.initState();
    _loadExistingRequests();
  }

  /// Load existing bookings for this user and mark matching rides as "requested"
  Future<void> _loadExistingRequests() async {
    final token = await TokenStorage.readToken();
    if (token == null) return;

    final res = await http.get(
      Uri.parse('$_baseUrl/rides/bookings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final List<dynamic> bookings = body['bookings'] ?? [];
      for (var b in bookings) {
        if (b['status'] == 'requested') {
          final rideId = b['rideId'] as String;
          final idx = widget.rides.indexWhere((r) => r['rideId'] == rideId);
          if (idx != -1) {
            setState(() {
              _requestedIndices.add(idx);
              if (b.containsKey('bookingId')) {
                _bookingIds[idx] = b['bookingId'] as String;
              }
            });
          }
        }
      }
    } else {
      // Optionally handle error
    }
  }

  /// Format a DateTime as DD/MM/YYYY
  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yy = dt.year.toString();
    return '$dd/$mm/$yy';
  }

  /// Launch phone dialer
  Future<void> _launchCaller(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot launch dialer')),
      );
    }
  }

  /// Book or cancel a ride request when the button is tapped
  Future<void> _toggleRequest(int index) async {
    final ride = widget.rides[index];
    final rideId = ride['rideId'] as String;
    final token = await TokenStorage.readToken();
    if (token == null) return;

    try {
      if (!_requestedIndices.contains(index)) {
        // Send book request
        final res = await http.post(
          Uri.parse('$_baseUrl/rides/$rideId/request'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (res.statusCode == 201) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final bookingId = body['bookingId'] as String;
          setState(() {
            _requestedIndices.add(index);
            _bookingIds[index] = bookingId;
          });
        } else {
          final error = jsonDecode(res.body)['message'] ?? 'Request failed';
          throw Exception(error);
        }
      } else {
        // Cancel existing request
        final bookingId = _bookingIds[index];
        if (bookingId == null) throw Exception('Missing bookingId');
        final res = await http.put(
          Uri.parse('$_baseUrl/rides/$rideId/requests/$bookingId/cancel'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
        if (res.statusCode == 200) {
          setState(() {
            _requestedIndices.remove(index);
            _bookingIds.remove(index);
          });
        } else {
          final error = jsonDecode(res.body)['message'] ?? 'Cancel failed';
          throw Exception(error);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// Build the card for each ride (UI unchanged)
  Widget _buildRideCard(
      BuildContext context, Map<String, dynamic> ride, int index) {
    final isRequested = _requestedIndices.contains(index);

    final riderName = ride['name'] as String;
    final phoneNumber = ride['phone'] as String;

    // Format date and time
    final dt = DateTime.parse(ride['date'].toString());
    final dateStr = _formatDate(dt);
    final rawTime = (ride['time'] as String).trim();
    final parts = rawTime.split(':');
    final hour = int.tryParse(parts[0])?.clamp(0, 23) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final timeStr = TimeOfDay(hour: hour, minute: minute).format(context);

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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                'L S:${luggage['small']} M:${luggage['medium']} L:${luggage['large']}',
                style: const TextStyle(fontSize: 14),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchCaller(phoneNumber),
                  icon: const Icon(Icons.call, color: AppTheme.primary),
                  label:
                      const Text('Call', style: TextStyle(color: AppTheme.primary)),
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
                  onPressed: () => _toggleRequest(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRequested ? Colors.grey : AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      isRequested ? 'Requested' : 'Book Ride',
                      key: ValueKey(isRequested),
                      style: const TextStyle(color: Colors.white),
                    ),
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
        // you can keep your existing route overview and date/time bar here
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
