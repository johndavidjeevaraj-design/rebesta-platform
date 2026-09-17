import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/services/partner_auth_service.dart';
import '../login/otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController =
      TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> _sendOtp() async {
  final mobile = phoneController.text.trim();

  if (mobile.length != 10) {
    _showMessage(
      'Enter a valid 10 digit mobile number',
    );
    return;
  }

  if (_loading) return;

  setState(() {
    _loading = true;
  });

  try {
    debugPrint('================================');
    debugPrint('📱 SENDING PARTNER OTP');
    debugPrint('Mobile: $mobile');
    debugPrint('================================');

    final sessionId =
        await PartnerAuthService.sendOtp(
      mobile: mobile,
    );

    debugPrint('================================');
    debugPrint('✅ OTP SENT SUCCESSFULLY');
    debugPrint('Session ID: $sessionId');
    debugPrint('Mounted: $mounted');
    debugPrint('================================');

    if (!mounted) {
      debugPrint('❌ LoginScreen is no longer mounted');
      return;
    }

    // IMPORTANT:
    // Navigate immediately after OTP is successfully sent.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return OtpScreen(
            mobile: mobile,
            sessionId: sessionId,
          );
        },
      ),
    );

    debugPrint('➡️ Navigating to OTP screen');
  } catch (e) {
    debugPrint('================================');
    debugPrint('❌ SEND OTP FAILED');
    debugPrint('$e');
    debugPrint('================================');

    if (!mounted) return;

    _showMessage(
      e.toString().replaceFirst(
        'Exception: ',
        '',
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }
}

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // ==================================================
              // LOGO
              // ==================================================

              Center(
                child: Image.asset(
                  'assets/logo/rebesta_logo.png',
                  width: 120,
                ),
              ),

              const SizedBox(height: 45),

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'Welcome Partner 👋',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Manage your restaurant smarter with Rebesta.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: AppColors.grey,
                ),
              ),

              const SizedBox(height: 45),

              // ==================================================
              // PHONE LABEL
              // ==================================================

              const Text(
                'Mobile Number',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // PHONE FIELD
              // ==================================================

              TextField(
                controller: phoneController,
                keyboardType:
                    TextInputType.phone,
                maxLength: 10,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration:
                    InputDecoration(
                  counterText: '',
                  hintText: 'Enter mobile number',
                  prefixIcon: const Padding(
                    padding:
                        EdgeInsets.only(
                      left: 16,
                      right: 10,
                    ),
                    child: Text(
                      '+91',
                      style: TextStyle(
                        fontFamily:
                            'Poppins',
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide: BorderSide(
                      color:
                          AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // SEND OTP BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _loading
                          ? null
                          : _sendOtp,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Text(
                          'Send OTP',
                          style: TextStyle(
                            fontFamily:
                                'Poppins',
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // ==================================================
              // TERMS
              // ==================================================

              const Center(
                child: Text(
                  "By continuing you agree to\n"
                  "Rebesta's Terms & Privacy Policy",
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}