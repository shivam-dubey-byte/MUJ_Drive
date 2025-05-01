import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muj_drive/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController
      _nameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _regNoCtrl,
      _vehicleCtrl,
      _licenseCtrl;
  String _role = '';
  bool _loading = true;

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
      _role = prefs.getString('role') ?? '';
      _nameCtrl.text    = prefs.getString('name')            ?? '';
      _emailCtrl.text   = prefs.getString('email')           ?? '';
      _phoneCtrl.text   = prefs.getString('phone')           ?? '';
      _regNoCtrl.text   = prefs.getString('registration')  ?? '';
      _vehicleCtrl.text = prefs.getString('vehicleDetails')  ?? '';
      _licenseCtrl.text = prefs.getString('drivingLicense')  ?? '';
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name',  _nameCtrl.text.trim());
    await prefs.setString('email', _emailCtrl.text.trim());
    await prefs.setString('phone', _phoneCtrl.text.trim());
    if (_role == 'Student') {
      await prefs.setString('registrationNo', _regNoCtrl.text.trim());
    } else {
      await prefs.setString('vehicleDetails', _vehicleCtrl.text.trim());
      await prefs.setString('drivingLicense', _licenseCtrl.text.trim());
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.primary,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name, email, phone always:
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Role-specific fields:
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

                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Changes'),
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
