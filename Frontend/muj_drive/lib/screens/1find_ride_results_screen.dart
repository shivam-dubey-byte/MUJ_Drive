// lib/screens/find_ride_results_screen.dart

import 'package:flutter/material.dart';
import 'package:muj_drive/theme/app_theme.dart';

class FindRideResultsScreen extends StatelessWidget {
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

  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yy = dt.year.toString();
    return '$dd/$mm/$yy';
  }

  Widget _buildRideCard(BuildContext context, Map<String, dynamic> r) {
    final dt = DateTime.parse(r['date'].toString());
    final dateStr = _formatDate(dt);

    final rawTime = (r['time'] as String).trim();
    TimeOfDay t;
    final ampmMatch = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*([AaPp][Mm])$');
    if (ampmMatch.hasMatch(rawTime)) {
      final m = ampmMatch.firstMatch(rawTime)!;
      int hour = int.parse(m.group(1)!);
      final minute = m.group(2) != null ? int.parse(m.group(2)!) : 0;
      final suf = m.group(3)!.toUpperCase();
      if (suf == 'PM' && hour < 12) hour += 12;
      if (suf == 'AM' && hour == 12) hour = 0;
      t = TimeOfDay(hour: hour, minute: minute);
    } else {
      final parts = rawTime.split(':');
      if (parts.length == 2) {
        t = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      } else {
        final digits = rawTime.replaceAll(RegExp(r'\D'), '');
        final hh = digits.length > 2
            ? int.tryParse(digits.substring(0, digits.length - 2)) ?? 0
            : 0;
        final mm = digits.length >= 2
            ? int.tryParse(digits.substring(digits.length - 2)) ?? 0
            : 0;
        t = TimeOfDay(hour: hh, minute: mm);
      }
    }
    final timeStr = t.format(context);

    final seats = r['seatsAvailable'];
    final luggage = r['luggage'] as Map<String, dynamic>;
    final riderName = r['name'] as String;

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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            riderName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling user…')),
                  );
                },
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
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking ride…')),
                  );
                },
                icon: const Icon(Icons.car_rental, color: Colors.white),
                label: const Text('Book Ride', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
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
        title: const Text('Available Rides'),
        backgroundColor: AppTheme.primary,
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Enhanced header with distinct pills for pickup & drop
        Container(
          margin: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.my_location, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        pickup,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        drop,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),

        // date/time bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 20, color: Colors.black54),
              const SizedBox(width: 6),
              Text(_formatDate(date), style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 24),
              const Icon(Icons.access_time, size: 20, color: Colors.black54),
              const SizedBox(width: 6),
              Text(time.format(context), style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),

        const SizedBox(height: 8),
        const Divider(height: 1),

        Expanded(
          child: rides.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.not_listed_location,
                          size: 48, color: Colors.black38),
                      SizedBox(height: 12),
                      Text(
                        'No rides found',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: rides.length,
                  itemBuilder: (_, i) => _buildRideCard(context, rides[i]),
                ),
        ),
      ]),
    );
  }
}
