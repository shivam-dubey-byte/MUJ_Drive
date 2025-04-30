// lib/screens/driver_signup.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:muj_drive/services/token_storage.dart';
import 'package:muj_drive/theme/app_theme.dart';
import 'package:muj_drive/screens/otp_verification.dart';

class DriverSignupForm extends StatefulWidget {
  const DriverSignupForm({Key? key}) : super(key: key);

  @override
  State<DriverSignupForm> createState() => _DriverSignupFormState();
}

class _DriverSignupFormState extends State<DriverSignupForm> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _vehicleCtrl  = TextEditingController();
  final _licenseCtrl  = TextEditingController();
  final _passCtrl     = TextEditingController();

  bool    _loading = false;
  String? _error;

  static const _baseUrl = 'https://mujdrive.shivamrajdubey.tech';

  Future<void> _onVerifyAndSignup() async {
    final name    = _nameCtrl.text.trim();
    final email   = _emailCtrl.text.trim();
    final phone   = _phoneCtrl.text.trim();
    final vehicle = _vehicleCtrl.text.trim();
    final license = _licenseCtrl.text.trim();
    final pass    = _passCtrl.text;

    if ([name, email, phone, vehicle, license, pass].any((s) => s.isEmpty)) {
      setState(() => _error = 'Please fill all fields');
      return;
    }

    // 1) Email OTP
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(email: email),
      ),
    );
    if (ok != true) return;

    // 2) Signup request
    setState(() { _loading = true; _error = null; });
    try {
      final uri = Uri.parse('$_baseUrl/auth/driver/signup');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name':          name,
          'email':         email,
          'phone':         phone,
          'vehicleDetails':vehicle,
          'drivingLicense':license,
          'password':pass,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final token = body['token'] as String?;
        if (token == null) {
          throw Exception('Signup succeeded but no token returned');
        }
        await TokenStorage.writeToken(token);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final msg = (jsonDecode(res.body)['message'] as String?) 
            ?? 'Signup failed';
        setState(() => _error = msg);
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vehicleCtrl,
            decoration: const InputDecoration(
              labelText: 'Vehicle Details',
              prefixIcon: Icon(Icons.directions_car),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _licenseCtrl,
            decoration: const InputDecoration(
              labelText: 'License Number',
              prefixIcon: Icon(Icons.credit_card),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passCtrl,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _onVerifyAndSignup,
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : const Text('Verify Email & Sign Up'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}
