import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  final String phone;

  const SignupScreen({
    super.key,
    required this.phone,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ===========================================================================
  // FORM
  // ===========================================================================

  final _formKey = GlobalKey<FormState>();

  // ===========================================================================
  // CONTROLLERS
  // ===========================================================================

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());

  // ===========================================================================
  // FOCUS NODES
  // ===========================================================================

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();

  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  // ===========================================================================
  // STATE
  // ===========================================================================

  int _currentStep = 1;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _agreeToTerms = false;

  bool _isLoading = false;
  bool _isVerifying = false;
  final bool _isResending = false;

  String? _otpSessionId;

  Timer? _resendTimer;
  int _resendSeconds = 0;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _phoneController.text = widget.phone.replaceAll('+91', '').trim();
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();

    for (final controller in _otpControllers) {
      controller.dispose();
    }

    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }

    _resendTimer?.cancel();

    super.dispose();
  }

  // ===========================================================================
  // STEP NAVIGATION
  // ===========================================================================

  void _goToStep2() {
    FocusScope.of(context).unfocus();

    if (!_validateStep1()) {
      return;
    }

    setState(() {
      _currentStep = 2;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;

        _passwordFocus.requestFocus();
      });
    });
  }

  void _goToStep1() {
    FocusScope.of(context).unfocus();

    setState(() {
      _currentStep = 1;
    });
  }

  void _goBackFromOtp() {
    FocusScope.of(context).unfocus();

    _resendTimer?.cancel();

    for (final controller in _otpControllers) {
      controller.clear();
    }

    setState(() {
      _currentStep = 2;
      _resendSeconds = 0;
      _otpSessionId = null;
    });
  }

  // ===========================================================================
  // STEP 1 VALIDATION
  // ===========================================================================

  bool _validateStep1() {
    final nameError = _validateName(_nameController.text);

    if (nameError != null) {
      _showError(nameError);
      _nameFocus.requestFocus();
      return false;
    }

    final emailError = _validateEmail(_emailController.text);

    if (emailError != null) {
      _showError(emailError);
      _emailFocus.requestFocus();
      return false;
    }

    final phoneError = _validatePhone(_phoneController.text);

    if (phoneError != null) {
      _showError(phoneError);
      _phoneFocus.requestFocus();
      return false;
    }

    return true;
  }

  // ===========================================================================
  // STEP 2 VALIDATION
  // ===========================================================================

  bool _validateStep2() {
    final passwordError = _validatePassword(
      _passwordController.text,
    );

    if (passwordError != null) {
      _showError(passwordError);
      _passwordFocus.requestFocus();
      return false;
    }

    final confirmError = _validateConfirmPassword(
      _confirmPasswordController.text,
    );

    if (confirmError != null) {
      _showError(confirmError);
      _confirmPasswordFocus.requestFocus();
      return false;
    }

    if (!_agreeToTerms) {
      _showError('Please agree to the Terms & Conditions');
      return false;
    }

    return true;
  }

  // ===========================================================================
  // SEND OTP
  // ===========================================================================

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();

    if (!_validateStep2()) {
      return;
    }

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();

      final sessionId = await authService.sendOtp(
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      if (sessionId.isEmpty) {
        throw Exception('Unable to create OTP session');
      }

      _otpSessionId = sessionId;

      for (final controller in _otpControllers) {
        controller.clear();
      }

      setState(() {
        _isLoading = false;
        _currentStep = 3;
      });

      _startResendTimer();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;

          _otpFocusNodes[0].requestFocus();
        });
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showError(_dioErrorMessage(
        e,
        fallback: 'Unable to send OTP',
      ));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showError(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ===========================================================================
  // VERIFY OTP
  // ===========================================================================

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    if (_isVerifying) {
      return;
    }

    final otp = _otpControllers
        .map((controller) => controller.text)
        .join();

    if (otp.length != 6) {
      _showError('Please enter the complete 6-digit code');
      return;
    }

    if (_otpSessionId == null || _otpSessionId!.isEmpty) {
      _showError(
        'OTP session expired. Please request a new OTP.',
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final authService = AuthService();

      final login = await authService.verifyOtp(
        phone: _phoneController.text.trim(),
        otp: otp,
        sessionId: _otpSessionId!,
      );

      

      // Existing customer.
      if (login != null) {
        if (!mounted) return;
        setState(() {
          _isVerifying = false;
        });

        context.go(AppRoutes.homeScreen);
        return;
      }

      // New customer.
      // OTP has been verified successfully.
      // Now create the actual account.
      await _createAccountAfterVerification();
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      _showError(
        _dioErrorMessage(
          e,
          fallback: 'Invalid OTP. Please try again.',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      _showError(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ===========================================================================
  // CREATE ACCOUNT AFTER OTP VERIFICATION
  // ===========================================================================

  Future<void> _createAccountAfterVerification() async {
    if (!mounted) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final authService = AuthService();

      await authService.signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      _showSuccessDialog();
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      _showError(
        _dioErrorMessage(
          e,
          fallback: 'Unable to create account',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      _showError(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ===========================================================================
  // RESEND OTP
  // ===========================================================================

  Future<void> _resendOtp() async {
  if (_resendSeconds > 0) return;

  try {
    final authService = AuthService();

    final sessionId = await authService.sendOtp(
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;

    _otpSessionId = sessionId;

    for (final controller in _otpControllers) {
      controller.clear();
    }

    setState(() {});

    _startResendTimer();

    _otpFocusNodes[0].requestFocus();

    _showInfo('OTP resent successfully');
  } on DioException catch (e) {
    if (!mounted) return;

    final message =
        e.response?.data?['message']?.toString() ??
        e.response?.data?['Details']?.toString() ??
        e.response?.data?['error']?.toString() ??
        'Failed to resend OTP';

    _showError(message);
  } catch (e) {
    if (!mounted) return;

    _showError(
      e.toString().replaceFirst('Exception: ', ''),
    );
  }
}

  // ===========================================================================
  // RESEND TIMER
  // ===========================================================================

  void _startResendTimer() {
    _resendTimer?.cancel();

    setState(() {
      _resendSeconds = 30;
    });

    _resendTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_resendSeconds <= 1) {
          timer.cancel();

          setState(() {
            _resendSeconds = 0;
          });
        } else {
          setState(() {
            _resendSeconds--;
          });
        }
      },
    );
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Please enter your full name';
    }

    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email';
    }

    if (!RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Please enter your phone number';
    }

    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      return 'Please enter a valid 10-digit number';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Please enter a password';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Include at least one uppercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Include at least one number';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirm = value ?? '';

    if (confirm.isEmpty) {
      return 'Please confirm your password';
    }

    if (confirm != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  // ===========================================================================
  // DIO ERROR
  // ===========================================================================

  String _dioErrorMessage(
    DioException error, {
    required String fallback,
  }) {
    final data = error.response?.data;

    if (data is Map) {
      final message = data['message'];

      if (message is List) {
        return message.join(', ');
      }

      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }

      final errorMessage = data['error'];

      if (errorMessage != null &&
          errorMessage.toString().trim().isNotEmpty) {
        return errorMessage.toString();
      }
    }

    return fallback;
  }

  // ===========================================================================
  // SNACKBARS
  // ===========================================================================

  void _showError(String message) {
    _showSnack(
      message,
      isError: true,
    );
  }

  void _showInfo(String message) {
    _showSnack(
      message,
      isError: false,
    );
  }

  void _showSnack(
    String message, {
    required bool isError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20,
          ),
          padding: EdgeInsets.zero,
          content: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isError
                    ? const [
                        Color(0xFFFFA51F),
                        Color(0xFFFF3D21),
                      ]
                    : const [
                        Color(0xFF22C55E),
                        Color(0xFF16A34A),
                      ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (isError
                          ? const Color(0xFFFF6428)
                          : const Color(0xFF16A34A))
                      .withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError
                      ? Icons.info_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    final double keyboardInset =
        MediaQuery.viewInsetsOf(context).bottom;

    final bool keyboardOpen = keyboardInset > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // =================================================================
            // BACKGROUND
            // =================================================================

            Positioned.fill(
              child: Image.asset(
                'assets/images/signup_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            // =================================================================
            // SIGNUP CARD
            // =================================================================

            Positioned(
              left: size.width < 600 ? 16 : 48,
              right: size.width < 600 ? 16 : 48,
              bottom: keyboardOpen
                  ? keyboardInset + 80
                  : 80,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.bottomCenter,
                child: _buildSignupPanel(
                  size,
                  keyboardOpen: keyboardOpen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SIGNUP PANEL
  // ===========================================================================

  Widget _buildSignupPanel(
    Size size, {
    required bool keyboardOpen,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: keyboardOpen
              ? size.height - 24
              : size.height * 0.62,
        ),
        padding: EdgeInsets.fromLTRB(
          size.width < 380 ? 18 : 22,
          2,
          size.width < 380 ? 18 : 22,
          10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.82),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Header
                _buildHeader(),

                const SizedBox(height: 10),

                // Step indicator
                _buildStepIndicator(),

                const SizedBox(height: 12),

                // Content
                AnimatedSize(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    reverseDuration:
                        const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (
                      child,
                      animation,
                    ) {
                      final slideAnimation =
                          Tween<Offset>(
                        begin: const Offset(0.03, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      );

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: slideAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: _currentStep == 1
                        ? _buildStep1(size)
                        : _currentStep == 2
                            ? _buildStep2(size)
                            : _buildStep3(size),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    String title;
    String subtitle;
    VoidCallback? backAction;

    switch (_currentStep) {
      case 1:
        title = 'Create Account';
        subtitle = 'Enter your details to get started.';
        break;

      case 2:
        title = 'Almost There!';
        subtitle = 'Set your password to continue.';
        backAction = _goToStep1;
        break;

      case 3:
      default:
        title = 'Verify Your Number';
        subtitle = 'Enter the 6-digit code we sent to';
        backAction = _goBackFromOtp;
        break;
    }

    return Row(
      children: [
        if (backAction != null)
          GestureDetector(
            onTap: backAction,
            child: Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.48),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.70),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 17,
                color: Color(0xFF374151),
              ),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 2),
              if (_currentStep == 3)
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF9CA3AF),
                    ),
                    children: [
                      TextSpan(
                        text: '$subtitle ',
                      ),
                      TextSpan(
                        text:
                            '+91 ${_phoneController.text}',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP INDICATOR
  // ===========================================================================

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepCircle(
          1,
          _currentStep >= 1,
        ),
        Expanded(
          child: _stepLine(
            _currentStep >= 2,
          ),
        ),
        _stepCircle(
          2,
          _currentStep >= 2,
        ),
        Expanded(
          child: _stepLine(
            _currentStep >= 3,
          ),
        ),
        _stepCircle(
          3,
          _currentStep >= 3,
        ),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            'Step $_currentStep of 3',
            key: ValueKey(_currentStep),
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [
                  Color(0xFFFFA51F),
                  Color(0xFFFF3D21),
                ],
              )
            : null,
        color: active
            ? null
            : const Color(0xFFE1E5EA),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _stepCircle(
    int step,
    bool active,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [
                  Color(0xFFFFA51F),
                  Color(0xFFFF3D21),
                ],
              )
            : null,
        color: active
            ? null
            : Colors.white.withValues(alpha: 0.48),
        shape: BoxShape.circle,
        border: Border.all(
          color: active
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.70),
          width: 1.2,
        ),
      ),
      child: Center(
        child: _currentStep > step
            ? const Icon(
                Icons.check_rounded,
                size: 13,
                color: Colors.white,
              )
            : Text(
                '$step',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: active
                      ? Colors.white
                      : const Color(0xFF9CA3AF),
                ),
              ),
      ),
    );
  }

  // ===========================================================================
  // STEP 1
  // ===========================================================================

  Widget _buildStep1(Size size) {
    return Column(
      key: const ValueKey('signup-step-1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          controller: _nameController,
          focusNode: _nameFocus,
          hint: 'Full name',
          icon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            _emailFocus.requestFocus();
          },
          validator: _validateName,
          size: size,
        ),

        const SizedBox(height: 12),

        _buildInputField(
          controller: _emailController,
          focusNode: _emailFocus,
          hint: 'Email address',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            _phoneFocus.requestFocus();
          },
          validator: _validateEmail,
          size: size,
        ),

        const SizedBox(height: 12),

        _buildPhoneField(size),

        const SizedBox(height: 14),

        _buildPrimaryButton(
          text: 'Continue',
          icon: Icons.arrow_forward_rounded,
          onTap: _goToStep2,
          loading: false,
          size: size,
        ),

        const SizedBox(height: 10),

        _buildSignInLink(size),
      ],
    );
  }

  // ===========================================================================
  // STEP 2
  // ===========================================================================

  Widget _buildStep2(Size size) {
    return Column(
      key: const ValueKey('signup-step-2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPasswordField(size),

        const SizedBox(height: 5),

        _buildPasswordStrength(),

        const SizedBox(height: 10),

        _buildConfirmPasswordField(size),

        const SizedBox(height: 10),

        _buildTerms(),

        const SizedBox(height: 12),

        // IMPORTANT:
        // Step 2 sends OTP.
        // Account is NOT created here.
        _buildPrimaryButton(
          text: 'Send OTP',
          icon: Icons.sms_outlined,
          onTap: _sendOtp,
          loading: _isLoading,
          size: size,
        ),

        const SizedBox(height: 10),

        _buildSocialSignup(size),

        const SizedBox(height: 8),

        _buildSignInLink(size),
      ],
    );
  }

  // ===========================================================================
  // STEP 3 — OTP
  // ===========================================================================

  Widget _buildStep3(Size size) {
    return Column(
      key: const ValueKey('signup-step-3'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFA51F),
                Color(0xFFFF3D21),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6428)
                    .withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),

        const SizedBox(height: 14),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
            (index) => _buildOtpBox(
              index,
              size,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive code? ",
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                color: const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w400,
              ),
            ),
            GestureDetector(
              onTap: _resendSeconds == 0 &&
                      !_isResending
                  ? _resendOtp
                  : null,
              child: _isResending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                      ),
                    )
                  : Text(
                      _resendSeconds == 0
                          ? 'Resend'
                          : 'Resend in ${_resendSeconds}s',
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _resendSeconds == 0
                            ? AppTheme.primary
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _buildPrimaryButton(
          text: 'Verify & Create Account',
          icon: Icons.check_rounded,
          onTap: _verifyOtp,
          loading: _isVerifying,
          size: size,
        ),

        const SizedBox(height: 8),

        GestureDetector(
          onTap: _goBackFromOtp,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 4,
            ),
            child: Text(
              'Change phone number',
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // OTP BOX
  // ===========================================================================

  Widget _buildOtpBox(
    int index,
    Size size,
  ) {
    final boxWidth =
        size.width < 380 ? 40.0 : 44.0;

    final boxHeight =
        size.width < 380 ? 46.0 : 50.0;

    return SizedBox(
      width: boxWidth,
      height: boxHeight,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF374151),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1]
                .requestFocus();
          } else if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1]
                .requestFocus();
          }

          setState(() {});

          final otp = _otpControllers
              .map((controller) => controller.text)
              .join();

          if (otp.length == 6 &&
              !_isVerifying) {
            FocusScope.of(context).unfocus();

            Future.microtask(() {
              if (!mounted) return;

              _verifyOtp();
            });
          }
        },
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white.withValues(
            alpha: 0.48,
          ),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.white.withValues(
                alpha: 0.85,
              ),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.white.withValues(
                alpha: 0.85,
              ),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppTheme.primary,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // INPUT FIELD
  // ===========================================================================

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required TextInputAction textInputAction,
    required ValueChanged<String> onSubmitted,
    required String? Function(String?) validator,
    required Size size,
    int? maxLength,
  }) {
    return SizedBox(
      height: size.width < 380 ? 40 : 46,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        maxLength: maxLength,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        autovalidateMode:
            AutovalidateMode.onUserInteraction,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF374151),
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFFB0B7C3),
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: const Color(0xFFAAB2BE),
          ),
          filled: true,
          fillColor: Colors.white.withValues(
            alpha: 0.48,
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          border: _inputBorder(),
          enabledBorder: _inputBorder(),
          focusedBorder: _focusedBorder(),
          errorBorder: _inputBorder(),
          focusedErrorBorder: _focusedBorder(),
          errorStyle: const TextStyle(
            fontSize: 0,
            height: 0,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PHONE FIELD
  // ===========================================================================

  Widget _buildPhoneField(Size size) {
    return SizedBox(
      height: size.width < 380 ? 40 : 46,
      child: TextFormField(
        controller: _phoneController,
        focusNode: _phoneFocus,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        maxLength: 10,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onFieldSubmitted: (_) {
          _goToStep2();
        },
        validator: _validatePhone,
        autovalidateMode:
            AutovalidateMode.onUserInteraction,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF374151),
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: 'Phone number',
          hintStyle: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFFB0B7C3),
          ),
          prefixIcon: const Icon(
            Icons.phone_outlined,
            size: 20,
            color: Color(0xFFAAB2BE),
          ),
          prefixText: '+91  ',
          prefixStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
          filled: true,
          fillColor: Colors.white.withValues(
            alpha: 0.48,
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          border: _inputBorder(),
          enabledBorder: _inputBorder(),
          focusedBorder: _focusedBorder(),
          errorBorder: _inputBorder(),
          focusedErrorBorder: _focusedBorder(),
          errorStyle: const TextStyle(
            fontSize: 0,
            height: 0,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PASSWORD FIELD
  // ===========================================================================

  Widget _buildPasswordField(Size size) {
    return SizedBox(
      height: size.width < 380 ? 40 : 46,
      child: TextFormField(
        controller: _passwordController,
        focusNode: _passwordFocus,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.next,
        onChanged: (_) {
          setState(() {});
        },
        onFieldSubmitted: (_) {
          _confirmPasswordFocus.requestFocus();
        },
        validator: _validatePassword,
        autovalidateMode:
            AutovalidateMode.onUserInteraction,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF374151),
        ),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFFB0B7C3),
          ),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: Color(0xFFAAB2BE),
          ),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscurePassword =
                    !_obscurePassword;
              });
            },
            splashRadius: 20,
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: const Color(0xFFAAB2BE),
            ),
          ),
          filled: true,
          fillColor: Colors.white.withValues(
            alpha: 0.48,
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          border: _inputBorder(),
          enabledBorder: _inputBorder(),
          focusedBorder: _focusedBorder(),
          errorBorder: _inputBorder(),
          focusedErrorBorder: _focusedBorder(),
          errorStyle: const TextStyle(
            fontSize: 0,
            height: 0,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CONFIRM PASSWORD FIELD
  // ===========================================================================

  Widget _buildConfirmPasswordField(Size size) {
    return SizedBox(
      height: size.width < 380 ? 40 : 46,
      child: TextFormField(
        controller: _confirmPasswordController,
        focusNode: _confirmPasswordFocus,
        obscureText: _obscureConfirmPassword,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) {
          _sendOtp();
        },
        validator: _validateConfirmPassword,
        autovalidateMode:
            AutovalidateMode.onUserInteraction,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF374151),
        ),
        decoration: InputDecoration(
          hintText: 'Confirm password',
          hintStyle: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFFB0B7C3),
          ),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: Color(0xFFAAB2BE),
          ),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscureConfirmPassword =
                    !_obscureConfirmPassword;
              });
            },
            splashRadius: 20,
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: const Color(0xFFAAB2BE),
            ),
          ),
          filled: true,
          fillColor: Colors.white.withValues(
            alpha: 0.48,
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          border: _inputBorder(),
          enabledBorder: _inputBorder(),
          focusedBorder: _focusedBorder(),
          errorBorder: _inputBorder(),
          focusedErrorBorder: _focusedBorder(),
          errorStyle: const TextStyle(
            fontSize: 0,
            height: 0,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BORDERS
  // ===========================================================================

  OutlineInputBorder _inputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Colors.white.withValues(
          alpha: 0.85,
        ),
      ),
    );
  }

  OutlineInputBorder _focusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: AppTheme.primary,
        width: 1.4,
      ),
    );
  }

  // ===========================================================================
  // PASSWORD STRENGTH
  // ===========================================================================

  Widget _buildPasswordStrength() {
    final password = _passwordController.text;

    if (password.isEmpty) {
      return const SizedBox(height: 2);
    }

    int strength = 0;

    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) {
      strength++;
    }
    if (RegExp(r'[0-9]').hasMatch(password)) {
      strength++;
    }
    if (RegExp(
      r'[!@#$%^&*(),.?":{}|<>]',
    ).hasMatch(password)) {
      strength++;
    }

    Color color;
    String label;

    switch (strength) {
      case 1:
        color = Colors.red;
        label = 'Weak';
        break;

      case 2:
        color = Colors.orange;
        label = 'Fair';
        break;

      case 3:
        color = const Color(0xFFFF8C00);
        label = 'Good';
        break;

      case 4:
        color = Colors.green;
        label = 'Strong';
        break;

      default:
        color = const Color(0xFFE5E7EB);
        label = '';
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            4,
            (index) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(
                    right: index < 3 ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: index < strength
                        ? color
                        : const Color(0xFFE5E7EB),
                    borderRadius:
                        BorderRadius.circular(3),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TERMS
  // ===========================================================================

  Widget _buildTerms() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (value) {
              setState(() {
                _agreeToTerms =
                    value ?? false;
              });
            },
            activeColor: AppTheme.primary,
            checkColor: Colors.white,
            side: const BorderSide(
              color: Color(0xFFD1D5DB),
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.dmSans(
                fontSize: 10.5,
                color: const Color(0xFF9CA3AF),
                height: 1.25,
              ),
              children: [
                const TextSpan(
                  text: 'I agree to the ',
                ),
                TextSpan(
                  text: 'Terms of Service',
                  style: GoogleFonts.dmSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const TextSpan(
                  text: ' and ',
                ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: GoogleFonts.dmSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // PRIMARY BUTTON
  // ===========================================================================

  Widget _buildPrimaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    required bool loading,
    required Size size,
  }) {
    return SizedBox(
      width: double.infinity,
      height: size.width < 380 ? 40 : 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFFA51F),
              Color(0xFFFF3D21),
            ],
          ),
          borderRadius:
              BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6428)
                  .withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onTap,
            borderRadius:
                BorderRadius.circular(16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<
                                Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          text,
                          style:
                              GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          icon,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SOCIAL SIGNUP
  // ===========================================================================

  Widget _buildSocialSignup(Size size) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: const Color(0xFFE4E6EA),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              child: Text(
                'or continue with',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color:
                      const Color(0xFF9CA3AF),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: const Color(0xFFE4E6EA),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                icon: Transform.translate(
                  offset:
                      const Offset(0, -3),
                  child: const Icon(
                    Icons.apple,
                    size: 25,
                    color: Colors.black,
                  ),
                ),
                text: 'Continue with Apple',
                onTap: () {},
                size: size,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildSocialButton(
                icon: _googleIcon(),
                text: 'Continue with Google',
                onTap: () {},
                size: size,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required String text,
    required VoidCallback onTap,
    required Size size,
  }) {
    return SizedBox(
      height: size.width < 380 ? 40 : 46,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE2E5E9),
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Center(
                    child: icon,
                  ),
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.dmSans(
                      fontSize:
                          size.width < 380
                              ? 8.5
                              : 9.5,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          const Color(0xFF171717),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _googleIcon() {
    return SvgPicture.asset(
      'assets/icons/google_g.svg',
      width: 20,
      height: 20,
    );
  }

  // ===========================================================================
  // SIGN IN LINK
  // ===========================================================================

  Widget _buildSignInLink(Size size) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();

          context.go(
            AppRoutes.loginScreen,
          );
        },
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.dmSans(
              fontSize:
                  size.width < 380
                      ? 11
                      : 12,
              color:
                  const Color(0xFF9CA3AF),
            ),
            children: [
              const TextSpan(
                text:
                    'Already have an account? ',
              ),
              TextSpan(
                text: 'Sign In',
                style: GoogleFonts.dmSans(
                  fontSize:
                      size.width < 380
                          ? 11
                          : 12,
                  fontWeight:
                      FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              const TextSpan(
                text: ' ›',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SUCCESS DIALOG
  // ===========================================================================

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          child: Container(
            padding:
                const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.97,
              ),
              borderRadius:
                  BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.12,
                  ),
                  blurRadius: 30,
                  offset:
                      const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration:
                      const BoxDecoration(
                    gradient:
                        LinearGradient(
                      colors: [
                        Color(0xFFFFA51F),
                        Color(0xFFFF3D21),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Account Created!',
                  style:
                      GoogleFonts.dmSans(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        const Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Your account has been created and verified successfully.',
                  textAlign:
                      TextAlign.center,
                  style:
                      GoogleFonts.dmSans(
                    fontSize: 12.5,
                    color:
                        const Color(0xFF9CA3AF),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: DecoratedBox(
                    decoration:
                        BoxDecoration(
                      gradient:
                          const LinearGradient(
                        colors: [
                          Color(0xFFFFA51F),
                          Color(0xFFFF3D21),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                        );

                        context.go(
                          AppRoutes.homeScreen,
                        );
                      },
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.transparent,
                        shadowColor:
                            Colors.transparent,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                      ),
                      child: Text(
                        'Start Ordering',
                        style:
                            GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}