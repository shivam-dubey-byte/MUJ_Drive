// lib/screens/offer_ride_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:muj_drive/theme/app_theme.dart';

class OfferRideScreen extends StatefulWidget {
  const OfferRideScreen({Key? key}) : super(key: key);

  @override
  State<OfferRideScreen> createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends State<OfferRideScreen> {
  late GoogleMapController _mapController;
  final _formKey = GlobalKey<FormState>();

  final _pickupCtrl = TextEditingController();
  final _destCtrl   = TextEditingController();

  String? _pickupSelected;
  String? _destSelected;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  int _totalSeats = 0;
  int _availableSeats = 0;

  bool _smallSelected  = false;
  bool _mediumSelected = false;
  bool _largeSelected  = false;
  int  _smallCount  = 0;
  int  _mediumCount = 0;
  int  _largeCount  = 0;

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
      _markers.removeWhere((m) => m.markerId.value == 'pickup');
      _markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: pos,
        infoWindow: InfoWindow(title: 'Pickup', snippet: sel),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
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
      _markers.removeWhere((m) => m.markerId.value == 'dest');
      _markers.add(Marker(
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

  void _onOffer() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ride offered!')),
    );
  }

  Widget _buildStepper(String label, int value, void Function(int) onDelta) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => onDelta(-1),
          ),
          Text('$value', style: const TextStyle(fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onDelta(1),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: AppTheme.primary, width: 2),
      borderRadius: BorderRadius.circular(8),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offer Ride'),
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
            // ← changed initialChildSize to 0.9 so the form (through the Offer button) is visible immediately
            initialChildSize: 0.7,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (ctx, ctrl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: SingleChildScrollView(
                controller: ctrl,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // drag handle & header
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
                      const SizedBox(height: 12),
                      Text(
                        'Offer a Ride',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      gap,

                      // Pickup Autocomplete
                      Autocomplete<String>(
                        optionsBuilder: (tv) {
                          final t = tv.text.trim().toLowerCase();
                          if (t.isEmpty) return const <String>[];
                          return _places.keys
                              .where((p) => p.toLowerCase().contains(t))
                              .where((p) => p != _destSelected)
                              .toList();
                        },
                        fieldViewBuilder: (ctx, ctrl, fn, sb) => TextFormField(
                          controller: ctrl,
                          focusNode: fn,
                          decoration: InputDecoration(
                            labelText: 'Pickup Location',
                            prefixIcon: const Icon(Icons.my_location),
                            border: border,
                          ),
                          validator: (_) =>
                              _pickupSelected == null ? 'Required' : null,
                        ),
                        onSelected: _addPickupMarker,
                      ),
                      gap,

                      // Destination Autocomplete
                      Autocomplete<String>(
                        optionsBuilder: (tv) {
                          final t = tv.text.trim().toLowerCase();
                          if (t.isEmpty) return const <String>[];
                          return _places.keys
                              .where((p) => p.toLowerCase().contains(t))
                              .where((p) => p != _pickupSelected)
                              .toList();
                        },
                        fieldViewBuilder: (ctx, ctrl, fn, sb) => TextFormField(
                          controller: ctrl,
                          focusNode: fn,
                          decoration: InputDecoration(
                            labelText: 'Destination',
                            prefixIcon: const Icon(Icons.location_on),
                            border: border,
                          ),
                          validator: (_) =>
                              _destSelected == null ? 'Required' : null,
                        ),
                        onSelected: _addDestMarker,
                      ),
                      gap,

                      // Date & Time
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_selectedDate == null
                                ? 'Select Date'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                            onPressed: _pickDate,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(_selectedTime == null
                                ? 'Select Time'
                                : _selectedTime!.format(context)),
                            onPressed: _pickTime,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ]),
                      gap,

                      // Seats steppers in colored bordered boxes
                      Row(children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Total Seats',
                              prefixIcon: const Icon(Icons.event_seat),
                              border: border,
                              enabledBorder: border,
                              focusedBorder: border,
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => setState(() {
                                    _totalSeats = (_totalSeats - 1).clamp(0, 15);
                                    if (_availableSeats > _totalSeats) {
                                      _availableSeats = _totalSeats;
                                    }
                                  }),
                                ),
                                Text('$_totalSeats', style: const TextStyle(fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => setState(() {
                                    _totalSeats = (_totalSeats + 1).clamp(0, 15);
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Seats Available',
                              prefixIcon: const Icon(Icons.airline_seat_recline_extra),
                              border: border,
                              enabledBorder: border,
                              focusedBorder: border,
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => setState(() {
                                    _availableSeats = (_availableSeats - 1).clamp(0, _totalSeats);
                                  }),
                                ),
                                Text('$_availableSeats', style: const TextStyle(fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => setState(() {
                                    _availableSeats = (_availableSeats + 1).clamp(0, _totalSeats);
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),
                      gap,

                      // Luggage
                      Text(
                        'Luggage Space',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('S'),
                            selected: _smallSelected,
                            onSelected: (b) {
                              setState(() {
                                _smallSelected = b;
                                if (!b) _smallCount = 0;
                              });
                            },
                            selectedColor: AppTheme.secondary.withOpacity(0.3),
                          ),
                          ChoiceChip(
                            label: const Text('M'),
                            selected: _mediumSelected,
                            onSelected: (b) {
                              setState(() {
                                _mediumSelected = b;
                                if (!b) _mediumCount = 0;
                              });
                            },
                            selectedColor: AppTheme.secondary.withOpacity(0.3),
                          ),
                          ChoiceChip(
                            label: const Text('L'),
                            selected: _largeSelected,
                            onSelected: (b) {
                              setState(() {
                                _largeSelected = b;
                                if (!b) _largeCount = 0;
                              });
                            },
                            selectedColor: AppTheme.secondary.withOpacity(0.3),
                          ),
                        ],
                      ),
                      gap,

                      if (_smallSelected)
                        _buildStepper(
                          'Small Bags',
                          _smallCount,
                          (d) => setState(() {
                            _smallCount = (_smallCount + d).clamp(0, 15);
                          }),
                        ),
                      if (_mediumSelected)
                        _buildStepper(
                          'Medium Bags',
                          _mediumCount,
                          (d) => setState(() {
                            _mediumCount = (_mediumCount + d).clamp(0, 15);
                          }),
                        ),
                      if (_largeSelected)
                        _buildStepper(
                          'Large Bags',
                          _largeCount,
                          (d) => setState(() {
                            _largeCount = (_largeCount + d).clamp(0, 15);
                          }),
                        ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: _onOffer,
                        child: const Text('Offer Ride'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
