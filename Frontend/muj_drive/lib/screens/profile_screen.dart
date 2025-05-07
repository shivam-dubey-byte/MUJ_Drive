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
  late TextEditingController _nameCtrl,
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
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _regNoCtrl = TextEditingController();
    _vehicleCtrl = TextEditingController();
    _licenseCtrl = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? 'Student';
      _nameCtrl.text = prefs.getString('name') ?? '';
      _emailCtrl.text = prefs.getString('email') ?? '';
      _phoneCtrl.text = prefs.getString('phone') ?? '';
      _regNoCtrl.text = prefs.getString('registrationNo') ?? '';
      _vehicleCtrl.text = prefs.getString('vehicleDetails') ?? '';
      _licenseCtrl.text = prefs.getString('drivingLicense') ?? '';
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
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
          child: LayoutBuilder(builder: (context, constraints) {
            final cardWidth = constraints.maxWidth * 0.95;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardWidth),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child:
                            Icon(Icons.person, size: 56, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Your Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _role,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
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
                                // Full Name
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

                                // Truncated email with tap-to-show
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

                                // Phone Number
                                TextFormField(
                                  controller: _phoneCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone Number',
                                    prefixIcon: Icon(Icons.phone),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (v) =>
                                      v!.trim().isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 16),

                                // Role‑specific fields
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
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: _saveProfile,
                                    child: const Text(
                                      'Save Changes',
                                      style: TextStyle(fontSize: 16),
                                    ),
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
