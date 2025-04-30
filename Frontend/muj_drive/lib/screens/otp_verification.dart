// lib/screens/otp_verification.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:muj_drive/theme/app_theme.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  static const _baseUrl = 'https://mujdrive.shivamrajdubey.tech';

  const OtpVerificationScreen({Key? key, required this.email})
      : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _sending = true;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final uri = Uri.parse('${OtpVerificationScreen._baseUrl}/auth/send-otp');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );
      if (res.statusCode != 200) {
        throw Exception(jsonDecode(res.body)['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    final uri = Uri.parse('${OtpVerificationScreen._baseUrl}/auth/verify-otp');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'otp': otp}),
      );
      if (res.statusCode == 200) {
        Navigator.of(context).pop(true);
      } else {
        throw Exception(jsonDecode(res.body)['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          child: Card(
            elevation: 8,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _sending
                  ? const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Enter the 6-digit code sent to\n${widget.email}',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Highlight + OTP fields aligned via Stack
                        SizedBox(
                          height: 50, // match PinCode fieldHeight
                          child: Stack(
                            children: [
                              // Highlight box
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.highlight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              // OTP fields on top
                              Align(
                                alignment: Alignment.center,
                                child: PinCodeTextField(
                                  appContext: context,
                                  length: 6,
                                  controller: _otpController,
                                  onChanged: (_) {},
                                  keyboardType: TextInputType.number,
                                  pinTheme: PinTheme(
                                    shape: PinCodeFieldShape.box,
                                    borderRadius: BorderRadius.circular(8),
                                    fieldHeight: 50,
                                    fieldWidth: 40,
                                    activeColor: AppTheme.primary,
                                    inactiveColor: Colors.grey.shade300,
                                    selectedColor: AppTheme.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _verifying ? null : _verifyOtp,
                          child: _verifying
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white),
                                )
                              : const Text('Verify & Continue'),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
