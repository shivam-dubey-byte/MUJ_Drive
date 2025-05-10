import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  final _nameCtrl = TextEditingController();
  final _regNoCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  String? _error;

  String? _nameError;
  String? _emailError;
  String? _regNoError;
  String? _phoneError;
  String? _passError;

  static const _baseUrl = 'https://mujdrive.shivamrajdubey.tech';

  Future<void> _onVerifyAndSignup() async {
    final email = _emailCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final regNo = _regNoCtrl.text.trim();
    var phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text;

    // Clear previous errors
    setState(() {
      _nameError =
          _emailError = _regNoError = _phoneError = _passError = _error = null;
    });

    // Validation patterns
    final emailPattern =
        RegExp(r'^([A-Za-z]+)\.([A-Za-z0-9]+)@muj\.manipal\.edu$');
    final passPattern =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&]).{8,}$');

    bool hasError = false;

    if (name.isEmpty) {
      _nameError = 'Please enter your full name';
      hasError = true;
    }

    if (email.isEmpty) {
      _emailError = 'Please enter your MUJ Outlook address';
      hasError = true;
    } else if (!emailPattern.hasMatch(email)) {
      _emailError = 'Incorrect MUJ Outlook format';
      hasError = true;
    }

    if (regNo.isEmpty) {
      _regNoError = 'Please enter your registration number';
      hasError = true;
    } else if (_emailError == null) {
      final match = emailPattern.firstMatch(email);
      final regFromEmail = match?.group(2) ?? '';
      if (regFromEmail.toLowerCase() != regNo.toLowerCase()) {
        _regNoError = 'Registration number must match the one in your email';
        hasError = true;
      }
    }

    // Sanitize and validate phone
    phone = phone.replaceFirst(RegExp(r'^(?:\+91|0)+'), '');
    if (phone.isEmpty) {
      _phoneError = 'Please enter your phone number';
      hasError = true;
    } else if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      _phoneError = 'Phone number must be exactly 10 digits';
      hasError = true;
    }

    if (pass.isEmpty) {
      _passError = 'Please enter a password';
      hasError = true;
    } else if (!passPattern.hasMatch(pass)) {
      _passError =
          'Min 8 chars (A-Z, a-z, 0-9, !@#\$&)\n(e.g. Ex@mple1)';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    // Email OTP step
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: email)),
    );
    if (ok != true) return;

    // Signup request
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('$_baseUrl/auth/student/signup');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'registrationNo': regNo,
          'email': email,
          'phone': phone,
          'password': pass,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final token = body['token'] as String?;
        if (token == null) throw Exception('No token returned');

        final prefs = await SharedPreferences.getInstance();
        await TokenStorage.writeToken(token);
        await prefs.setString('email', email);
        await prefs.setString('name', name);
        await prefs.setString('registrationNo', regNo);
        await prefs.setString('phone', phone);

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final msg = jsonDecode(res.body)['message'] ?? 'Signup failed';
        setState(() => _error = msg);
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person),
              errorText: _nameError,
              errorMaxLines: 2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: InputDecoration(
              labelText: 'MUJ Outlook',
              prefixIcon: const Icon(Icons.email),
              errorText: _emailError,
              errorMaxLines: 2,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regNoCtrl,
            decoration: InputDecoration(
              labelText: 'Registration No.',
              prefixIcon: const Icon(Icons.badge),
              errorText: _regNoError,
              errorMaxLines: 2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone),
              errorText: _phoneError,
              errorMaxLines: 2,
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
              errorText: _passError,
              errorMaxLines: 2,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: _loading ? null : _onVerifyAndSignup,
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text('Sign Up'),
            ),
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
