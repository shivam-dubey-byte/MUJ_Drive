// lib/screens/find_ride_results_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  /// Tracks which ride‐indexes are “requested”
  final Set<int> _requestedIndices = {};

  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yy = dt.year.toString();
    return '$dd/$mm/$yy';
  }

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

  Widget _buildRideCard(BuildContext context, Map<String, dynamic> ride, int index) {
    final isRequested = _requestedIndices.contains(index);

    // rider info
    final riderName = ride['name'] as String;
    final phoneNumber = ride['phone'] as String; // phone from data

    // date & time
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
                  label: const Text('Call', style: TextStyle(color: AppTheme.primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (isRequested) {
                        _requestedIndices.remove(index);
                      } else {
                        _requestedIndices.add(index);
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRequested ? Colors.grey : AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        // route overview
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(widget.drop,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ]),
        ),
        // date/time bar
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
            Text(_formatDate(widget.date), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(width: 24),
            const Icon(Icons.access_time, size: 20, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(widget.time.format(context), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
                  itemBuilder: (_, i) => _buildRideCard(context, widget.rides[i], i),
                ),
        ),
      ]),
    );
  }
}
