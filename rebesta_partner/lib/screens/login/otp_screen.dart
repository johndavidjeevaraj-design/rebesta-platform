import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/services/partner_fcm_service.dart';
import '../../core/constants/colors.dart';
import '../../core/services/partner_auth_service.dart';
import '../dashboard/dashboard_screen.dart';

class OtpScreen extends StatefulWidget {
  final String mobile;
  final String sessionId;

  const OtpScreen({
    super.key,
    required this.mobile,
    required this.sessionId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // ============================================================
  // OTP CONTROLLERS
  // ============================================================

  final List<TextEditingController> otpControllers =
      List.generate(
    6,
    (_) => TextEditingController(),
  );

  // ============================================================
  // OTP FOCUS NODES
  // ============================================================

  final List<FocusNode> otpFocusNodes =
      List.generate(
    6,
    (_) => FocusNode(),
  );

  // ============================================================
  // STATE
  // ============================================================

  int seconds = 60;

  bool isLoading = false;
  bool isResending = false;

  Timer? _timer;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _currentSessionId = widget.sessionId;
    _startTimer();
  }

  // ============================================================
  // TIMER
  // ============================================================

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      seconds = 60;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (seconds <= 1) {
          timer.cancel();

          setState(() {
            seconds = 0;
          });

          return;
        }

        setState(() {
          seconds--;
        });
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _timer?.cancel();

    for (final controller in otpControllers) {
      controller.dispose();
    }

    for (final node in otpFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // GET OTP
  // ============================================================

  String _getOtp() {
    return otpControllers
        .map(
          (controller) => controller.text.trim(),
        )
        .join();
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> verifyOtp() async {
    if (isLoading) return;

    final otp = _getOtp();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter the 6 digit OTP',
          ),
        ),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      final result =
          await PartnerAuthService.verifyOtp(
        mobile: widget.mobile,
        otp: otp,
        sessionId: _currentSessionId,
      );

      if (!mounted) return;

      // ========================================================
      // OTP SUCCESS
      // ========================================================

      if (result['success'] == true &&
          result['registered'] == true) {

        await PartnerFcmService.initialize();

        if (!mounted) return;
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const DashboardScreen(),
          ),
          (route) => false,
        );

        return;
      }

      throw Exception(
        result['message']?.toString() ??
            'OTP verification failed',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<void> resendOtp() async {
    if (seconds > 0 || isResending || isLoading) {
      return;
    }

    setState(() {
      isResending = true;
    });

    try {
      final newSessionId =
          await PartnerAuthService.sendOtp(
        mobile: widget.mobile,
      );

      if (!mounted) return;

      // We cannot change widget.sessionId because it is final.
      // So this screen needs the new session ID for future verify.
      _currentSessionId = newSessionId;

      for (final controller in otpControllers) {
        controller.clear();
      }

      _startTimer();

      otpFocusNodes.first.requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'OTP sent successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isResending = false;
        });
      }
    }
  }

  // ============================================================
  // CURRENT SESSION ID
  // ============================================================

  late String _currentSessionId;

  // ============================================================
  // BUILD OTP BOX
  // ============================================================

  Widget otpBox(int index) {
    return SizedBox(
      width: 48,
      height: 58,
      child: TextField(
        controller: otpControllers[index],
        focusNode: otpFocusNodes[index],

        textAlign: TextAlign.center,

        keyboardType: TextInputType.number,

        textInputAction:
            index == 5
                ? TextInputAction.done
                : TextInputAction.next,

        maxLength: 1,

        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),

        decoration: InputDecoration(
          counterText: '',

          filled: true,
          fillColor: Colors.white,

          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 14,
          ),

          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),

            borderSide: BorderSide.none,
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),

            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),

            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),

        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              otpFocusNodes[index + 1]
                  .requestFocus();
            } else {
              FocusScope.of(context)
                  .unfocus();
            }
          }
        },

        onSubmitted: (_) {
          if (index == 5) {
            verifyOtp();
          }
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        elevation: 0,

        backgroundColor:
            Colors.transparent,

        foregroundColor:
            AppColors.black,

        title: const Text(
          'Verify OTP',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 24,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 25),

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'Verify your number',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 30,
                  color: AppColors.black,
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // DESCRIPTION
              // ==================================================

              Text(
                'Enter the 6 digit code sent to',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 4),

              // ==================================================
              // MOBILE NUMBER
              // ==================================================

              Text(
                '+91 ${widget.mobile}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w600,
                  color: AppColors.black,
                ),
              ),

              const SizedBox(height: 40),

              // ==================================================
              // OTP BOXES
              // ==================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: List.generate(
                  6,
                  (index) =>
                      otpBox(index),
                ),
              ),

              const SizedBox(height: 35),

              // ==================================================
              // VERIFY BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 54,

                child: ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () => verifyOtp(),

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,

                    foregroundColor:
                        Colors.white,

                    disabledBackgroundColor:
                        AppColors.primary
                            .withValues(
                          alpha: 0.5,
                        ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),

                    elevation: 0,
                  ),

                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify OTP',
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

              const SizedBox(height: 25),

              // ==================================================
              // RESEND
              // ==================================================

              Center(
                child: GestureDetector(
                  onTap:
                      seconds == 0 &&
                              !isResending
                          ? resendOtp
                          : null,

                  child: isResending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          seconds == 0
                              ? 'Resend OTP'
                              : 'Resend OTP in ${seconds}s',

                          style: TextStyle(
                            fontFamily:
                                'Poppins',
                            color:
                                seconds == 0
                                    ? AppColors.primary
                                    : Colors.grey,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}