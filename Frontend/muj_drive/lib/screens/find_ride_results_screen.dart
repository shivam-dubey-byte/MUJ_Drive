// lib/screens/find_ride_results_screen.dart

import 'package:flutter/material.dart';
import 'package:muj_drive/theme/app_theme.dart';

class FindRideResultsScreen extends StatelessWidget {
  final String pickup, drop;
  final DateTime date;
  final TimeOfDay time;

  const FindRideResultsScreen({
    Key? key,
    required this.pickup,
    required this.drop,
    required this.date,
    required this.time,
  }) : super(key: key);

  // 10 dummy rides
  List<Map<String, dynamic>> get _dummyRides {
    return List.generate(10, (i) {
      final d = date.add(Duration(days: i));
      final t = TimeOfDay(hour: (8 + i) % 24, minute: (i * 15) % 60);
      return {
        'name': 'Rider ${i + 1}',
        'date': d,
        'time': t,
        'seatsAvailable': (i % 4) + 1,
        'luggage': {
          'small': (i + 1) % 3,
          'medium': (i + 2) % 2,
          'large': (i + 3) % 4,
        },
      };
    });
  }

  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yy = dt.year.toString();
    return '$dd/$mm/$yy';
  }

  Widget _buildRideCard(BuildContext context, Map<String, dynamic> r) {
    final dateStr = _formatDate(r['date'] as DateTime);
    final t = r['time'] as TimeOfDay;
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
          // Rider name
          Text(
            riderName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Date & Time row
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
          // Seats & luggage row
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
          // Buttons row
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling user…')),
                  );
                },
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
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking ride…')),
                  );
                },
                icon: const Icon(
                  Icons.car_rental,
                  color: Colors.white,
                ),
                label: const Text(
                  'Book Ride',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    final rides = _dummyRides;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rides'),
        backgroundColor: AppTheme.primary,
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header
        Container(
          color: AppTheme.primary.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.my_location, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pickup,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.location_on, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  drop,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              '${_formatDate(date)} at ${time.format(context)}',
              style: const TextStyle(color: Colors.black54),
            ),
          ]),
        ),
        const Divider(height: 1),
        // Cards list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: rides.length,
            itemBuilder: (_, i) => _buildRideCard(context, rides[i]),
          ),
        ),
      ]),
    );
  }
}
