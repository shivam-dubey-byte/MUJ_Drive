// lib/screens/find_ride_screen.dart

import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muj_drive/services/token_storage.dart';
import 'package:muj_drive/theme/app_theme.dart';
import 'find_ride_results_screen.dart';

class FindRideScreen extends StatefulWidget {
  const FindRideScreen({Key? key}) : super(key: key);

  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  static const _baseUrl = 'https://mujdriveride.shivamrajdubey.tech';

  late GoogleMapController _mapController;
  final _formKey = GlobalKey<FormState>();
  final _pickupCtrl = TextEditingController();
  final _destCtrl   = TextEditingController();

  String? _pickupSelected;
  String? _destSelected;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(23.2599, 77.4126),
    zoom: 14,
  );

  static const Map<String, LatLng> _places = {
    'Manipal University Jaipur (MUJ)'       : LatLng(26.8429063, 75.56542888),
    'Jaipur Junction Railway Station (JP)'  : LatLng(26.9208,      75.7866),
    'Durgapura Railway Station (DPA)'       : LatLng(26.8549,      75.7867),
    'Sindhi Camp Inter‐State Bus Terminal'  : LatLng(26.922563,    75.799747),
    'Government Hostel Circle Bus Stop'     : LatLng(26.9178,      75.8014),
    'Jaipur International Airport (JAI)'    : LatLng(26.82417,     75.81222),
    '200 Feet Bypass Road ("200 Feet Road")': LatLng(26.8761133,   75.731446),
  };

  final Set<Marker> _markers = {};
  Polyline? _routeLine;

  @override
  void initState() {
    super.initState();
    _pickupCtrl.addListener(_onPickupTextChanged);
    _destCtrl.addListener(_onDestTextChanged);
  }

  @override
  void dispose() {
    _pickupCtrl.removeListener(_onPickupTextChanged);
    _destCtrl.removeListener(_onDestTextChanged);
    _pickupCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onPickupTextChanged() {
    if (_pickupCtrl.text.isEmpty && _pickupSelected != null) {
      setState(() {
        _pickupSelected = null;
        _markers.removeWhere((m) => m.markerId.value == 'pickup');
        _routeLine = null;
      });
    }
  }

  void _onDestTextChanged() {
    if (_destCtrl.text.isEmpty && _destSelected != null) {
      setState(() {
        _destSelected = null;
        _markers.removeWhere((m) => m.markerId.value == 'dest');
        _routeLine = null;
      });
    }
  }

  Future<void> _fitBounds(LatLng a, LatLng b) async {
    final sw = LatLng(min(a.latitude, b.latitude), min(a.longitude, b.longitude));
    final ne = LatLng(max(a.latitude, b.latitude), max(a.longitude, b.longitude));
    await _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: sw, northeast: ne),
        50,
      ),
    );
  }

  void _addPickupMarker(String sel) {
    final pos = _places[sel]!;
    setState(() {
      _pickupSelected = sel;
      _pickupCtrl.text = sel;
      _markers
        ..removeWhere((m) => m.markerId.value == 'pickup')
        ..add(Marker(
          markerId: const MarkerId('pickup'),
          position: pos,
          infoWindow: InfoWindow(title: 'Pickup', snippet: sel),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ));
      _routeLine = null;
    });
    _mapController.animateCamera(CameraUpdate.newLatLng(pos));
    if (_destSelected != null) _updateRoute();
  }

  void _addDestMarker(String sel) {
    final pos = _places[sel]!;
    setState(() {
      _destSelected = sel;
      _destCtrl.text = sel;
      _markers
        ..removeWhere((m) => m.markerId.value == 'dest')
        ..add(Marker(
          markerId: const MarkerId('dest'),
          position: pos,
          infoWindow: InfoWindow(title: 'Destination', snippet: sel),
        ));
      _routeLine = null;
    });
    _mapController.animateCamera(CameraUpdate.newLatLng(pos));
    if (_pickupSelected != null) _updateRoute();
  }

  Future<void> _updateRoute() async {
    final origin = _places[_pickupSelected!]!;
    final dest   = _places[_destSelected!]!;
    setState(() {
      _routeLine = Polyline(
        polylineId: const PolylineId('route'),
        points: [origin, dest],
        color: AppTheme.primary,
        width: 5,
      );
    });
    await _fitBounds(origin, dest);
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? now,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _searchRides() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await TokenStorage.readToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to search.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final prefs   = await SharedPreferences.getInstance();
    final myPhone = prefs.getString('phone'); // matches ProfileScreen key :contentReference[oaicite:2]{index=2}:contentReference[oaicite:3]{index=3}

    final body = {
      'pickupLocation': _pickupSelected!,
      'dropLocation':   _destSelected!,
      'date':           _selectedDate!.toIso8601String().split('T').first,
      'time':           _selectedTime!.format(context),
    };

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/rides/find-ride'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        var rides  = (data['rides'] as List).cast<Map<String, dynamic>>();

        // **filter out** any ride whose root `phone` equals the user’s phone :contentReference[oaicite:4]{index=4}:contentReference[oaicite:5]{index=5}
        if (myPhone != null) {
          rides = rides.where((r) => (r['phone'] as String) != myPhone).toList();
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FindRideResultsScreen(
              pickup: _pickupSelected!,
              drop:   _destSelected!,
              date:   _selectedDate!,
              time:   _selectedTime!,
              rides:  rides,
            ),
          ),
        );
      } else {
        final msg = jsonDecode(res.body)['message'] ?? 'Error ${res.statusCode}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Ride'),
        backgroundColor: AppTheme.primary,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialCamera,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            polylines: _routeLine != null ? {_routeLine!} : {},
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            builder: (ctx, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: scrollCtrl,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      gap,

                      // Pickup Location
                      Autocomplete<String>(
                        optionsBuilder: (tv) {
                          final input = tv.text.trim().toLowerCase();
                          if (input.isEmpty) return const <String>[];
                          return _places.keys
                              .where((p) => p.toLowerCase().contains(input))
                              .where((p) => p != _destSelected)
                              .toList();
                        },
                        fieldViewBuilder: (ctx, ctrl, fn, sb) => TextFormField(
                          controller: ctrl,
                          focusNode: fn,
                          decoration: const InputDecoration(
                            labelText: 'Pickup Location',
                            prefixIcon: Icon(Icons.my_location),
                          ),
                          validator: (_) => _pickupSelected == null ? 'Required' : null,
                        ),
                        onSelected: _addPickupMarker,
                      ),
                      gap,

                      // Destination Location
                      Autocomplete<String>(
                        optionsBuilder: (tv) {
                          final input = tv.text.trim().toLowerCase();
                          if (input.isEmpty) return const <String>[];
                          return _places.keys
                              .where((p) => p.toLowerCase().contains(input))
                              .where((p) => p != _pickupSelected)
                              .toList();
                        },
                        fieldViewBuilder: (ctx, ctrl, fn, sb) => TextFormField(
                          controller: ctrl,
                          focusNode: fn,
                          decoration: const InputDecoration(
                            labelText: 'Destination',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (_) => _destSelected == null ? 'Required' : null,
                        ),
                        onSelected: _addDestMarker,
                      ),
                      gap,

                      // Date & Time Pickers
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _selectedDate == null
                                  ? 'Select Date'
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            ),
                            onPressed: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              _selectedTime == null
                                  ? 'Select Time'
                                  : _selectedTime!.format(context),
                            ),
                            onPressed: _pickTime,
                          ),
                        ),
                      ]),
                      gap,

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _searchRides();
                          }
                        },
                        child: const Text('Search'),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
