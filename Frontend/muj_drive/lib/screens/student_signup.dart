import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:muj_drive/services/token_storage.dart';
import 'package:muj_drive/theme/app_theme.dart';
import 'package:muj_drive/screens/otp_verification.dart';

class StudentSignupForm extends StatefulWidget {
  const StudentSignupForm({Key? key}) : super(key: key);

  @override
  State<StudentSignupForm> createState() => _StudentSignupFormState();
}

class _StudentSignupFormState extends State<StudentSignupForm> {
  final _emailCtrl = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _regNoCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  bool    _loading = false;
  String? _error;

  static const _baseUrl = 'https://mujdrive.shivamrajdubey.tech';

  Future<void> _onVerifyAndSignup() async {
    final email = _emailCtrl.text.trim();
    final name  = _nameCtrl.text.trim();
    final regNo = _regNoCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pass  = _passCtrl.text;

    if ([email, name, regNo, phone, pass].any((s) => s.isEmpty)) {
      setState(() => _error = 'Please fill all fields');
      return;
    }

    // 1) Email OTP
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: email)),
    );
    if (ok != true) return;

    // 2) Signup request
    setState(() { _loading = true; _error = null; });
    try {
      final uri = Uri.parse('$_baseUrl/auth/student/signup');
      final res = await http.post(
        uri,
        headers: {'Content-Type':'application/json'},
        body: jsonEncode({
          'name':           name,
          'registrationNo': regNo,
          'email':          email,
          'phone':          phone,
          'password':       pass,
        }),
      );

      // treat 200 and 201 as success
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final token = body['token'] as String?;
        if (token == null) {
          throw Exception('Signup succeeded but no token returned');
        }
        // Save token and go home
        await TokenStorage.writeToken(token);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final msg = jsonDecode(res.body)['message'] ?? 'Signup failed';
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
            controller: _regNoCtrl,
            decoration: const InputDecoration(
              labelText: 'Registration No.',
              prefixIcon: Icon(Icons.badge),
            ),
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
                    child: CircularProgressIndicator(color: Colors.white),
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
