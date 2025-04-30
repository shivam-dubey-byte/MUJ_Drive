// lib/screens/login_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muj_drive/theme/app_theme.dart';
import 'package:muj_drive/screens/student_signup.dart';
import 'package:muj_drive/screens/driver_signup.dart';

class LoginScreen extends StatefulWidget {
  /// 'Student' or 'Driver'
  final String userType;
  const LoginScreen({Key? key, required this.userType}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool showSignup = false;
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool    _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final pass  = _passwordController.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please enter both email & password');
      return;
    }

    setState(() {
      _loading = true;
      _error   = null;
    });

    try {
      // Choose endpoint based on userType
      final uri = Uri.parse(
        widget.userType == 'Student'
          ? 'https://mujdrive.shivamrajdubey.tech/auth/student/login'
          : 'https://mujdrive.shivamrajdubey.tech/auth/driver/login'
      );

      final res = await http.post(
        uri,
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({ 'email': email, 'password': pass }),
      );

      if (res.statusCode == 200) {
        final body  = jsonDecode(res.body);
        final token = body['token'] as String?;
        if (token == null) {
          throw Exception('Token not found in response');
        }

        // Persist JWT
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt', token);

        // Navigate to Home
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final msg = jsonDecode(res.body)['message'] ?? 'Login failed';
        setState(() => _error = msg);
      }
    } catch (e) {
      setState(() => _error = 'Error: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.userType == 'Student';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(showSignup
            ? '${widget.userType} Signup'
            : '${widget.userType} Login'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: showSignup
                    ? (isStudent
                        ? const StudentSignupForm()
                        : const DriverSignupForm())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            obscureText: true,
                          ),

                          // Forgot Password?
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/forgot-email');
                              },
                              child: const Text('Forgot Password?'),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Login button
                          ElevatedButton(
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white),
                                  )
                                : const Text('Login'),
                          ),

                          // Error message
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Toggle to Signup
                          TextButton(
                            onPressed: () =>
                                setState(() => showSignup = true),
                            child: const Text('Don’t have an account? Sign up'),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
