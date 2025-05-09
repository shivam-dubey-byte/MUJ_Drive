import 'dart:convert';                                // for jsonEncode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;               // new
import 'package:muj_drive/theme/app_theme.dart';
import 'package:muj_drive/services/token_storage.dart'; // new

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _baseUrl = 'https://mujdrive.shivamrajdubey.tech'; // new

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _regNoCtrl,
      _vehicleCtrl,
      _licenseCtrl;
  String _role = '';
  bool _loading = true, _saving = false; // track saving state

  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController();
    _emailCtrl   = TextEditingController();
    _phoneCtrl   = TextEditingController();
    _regNoCtrl   = TextEditingController();
    _vehicleCtrl = TextEditingController();
    _licenseCtrl = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role          = prefs.getString('role') ?? 'Student';
      _nameCtrl.text = prefs.getString('name') ?? '';
      _emailCtrl.text= prefs.getString('email') ?? '';
      _phoneCtrl.text= prefs.getString('phone') ?? '';
      _regNoCtrl.text= prefs.getString('registrationNo') ?? '';
      _vehicleCtrl.text = prefs.getString('vehicleDetails') ?? '';
      _licenseCtrl.text = prefs.getString('drivingLicense') ?? '';
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final token = await TokenStorage.readToken();               // :contentReference[oaicite:0]{index=0}:contentReference[oaicite:1]{index=1}
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      setState(() => _saving = false);
      return;
    }

    // build payload
    final body = {
      'name' : _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      if (_role == 'Student') 'registrationNo': _regNoCtrl.text.trim(),
      if (_role != 'Student') ...{
        'vehicleDetails': _vehicleCtrl.text.trim(),
        'drivingLicense': _licenseCtrl.text.trim(),
      },
    };

    try {
      final uri = Uri.parse('$_baseUrl/profile');
      final res = await http.put(
        uri,
        headers: {
          'Content-Type' : 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        // Update local cache just like before
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', _nameCtrl.text.trim());
        await prefs.setString('phone', _phoneCtrl.text.trim());
        if (_role == 'Student') {
          await prefs.setString('registrationNo', _regNoCtrl.text.trim());
        } else {
          await prefs.setString('vehicleDetails', _vehicleCtrl.text.trim());
          await prefs.setString('drivingLicense', _licenseCtrl.text.trim());
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } else {
        final msg = jsonDecode(res.body)['message'] ?? 'Update failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _regNoCtrl.dispose();
    _vehicleCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  void _showFullEmail() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Email Address'),
        content: SelectableText(_emailCtrl.text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (ctx, constraints) {
            final w = constraints.maxWidth * 0.95;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 56, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Your Name',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _role,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 24),

                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 16),

                                InkWell(
                                  onTap: _showFullEmail,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email),
                                      suffixIcon: Icon(Icons.info_outline),
                                    ),
                                    child: Text(
                                      _emailCtrl.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _phoneCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone Number',
                                    prefixIcon: Icon(Icons.phone),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 16),

                                if (_role == 'Student') ...[
                                  TextFormField(
                                    controller: _regNoCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Registration No.',
                                      prefixIcon: Icon(Icons.badge),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ] else ...[
                                  TextFormField(
                                    controller: _vehicleCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Vehicle Details',
                                      prefixIcon: Icon(Icons.directions_car),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _licenseCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Driving License',
                                      prefixIcon: Icon(Icons.credit_card),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _saving
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(color: Colors.white),
                                          )
                                        : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
