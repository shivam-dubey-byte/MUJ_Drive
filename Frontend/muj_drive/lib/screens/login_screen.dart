import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muj_drive/theme/app_theme.dart';
import 'package:muj_drive/screens/student_signup.dart';
import 'package:muj_drive/screens/driver_signup.dart';
import 'package:muj_drive/services/token_storage.dart';

class LoginScreen extends StatefulWidget {
  /// 'Student' or 'Driver'
  final String userType;
  const LoginScreen({Key? key, required this.userType}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool showSignup = false;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please enter both email & password');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // choose endpoint
      final uri = Uri.parse(
        widget.userType == 'Student'
            ? 'https://mujdrive.shivamrajdubey.tech/auth/student/login'
            : 'https://mujdrive.shivamrajdubey.tech/auth/driver/login',
      );

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': pass}),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final token = body['token'] as String?;
        final name = body['name'] as String?;
        final phone = body['phone'] as String?;

        if (token == null || name == null || phone == null) {
          throw Exception('Missing required fields');
        }

        final prefs = await SharedPreferences.getInstance();
        await TokenStorage.writeToken(token);

        // Save role so ProfileScreen can branch correctly
        await prefs.setString('role', widget.userType);
        await prefs.setString('name', name);
        await prefs.setString('email', email);
        await prefs.setString('phone', phone);

        if (widget.userType == 'Student') {
          // Redirect to home for Student
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Redirect to Driver Under Development page
          Navigator.pushReplacementNamed(context, '/driver-development');
        }
      } else {
        final msg = (jsonDecode(res.body)['message'] ?? 'Login failed') as String;
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
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.userType == 'Student';
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(showSignup ? '${widget.userType} Signup' : '${widget.userType} Login'),
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
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/forgot-email'),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white),
                                  )
                                : const Text('Login'),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => setState(() => showSignup = true),
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
