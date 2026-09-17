
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../login_screen/name_screen.dart';
import '../../home_screen/home_screen.dart';


import '../../../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String sessionId;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.sessionId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  // ============================================================
  // TIMER
  // ============================================================

  Timer? _timer;

  int _remainingSeconds = 29;

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = false;

  String? _message;

  // ============================================================
  // BURGER ANIMATION
  // SAME VISUAL STYLE AS LOGIN SCREEN
  // ============================================================

  late AnimationController _burgerController;
  late Animation<double> _burgerScale;
  late Animation<double> _burgerRotation;
  late Animation<double> _burgerOpacity;
  late Animation<Offset> _burgerSlide;

  // ============================================================
  // COLORS — SAME AS LOGIN SCREEN
  // ============================================================

  static const Color cream =
      Color(0xFFFCF9F5);

  static const Color ink =
      Color(0xFF2A1D1A);

  static const Color muted =
      Color(0xFF70625F);

  static const Color line =
      Color(0xFFEFEAE2);

  static const Color orange =
      Color(0xFFFF6C0E);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _startCountdown();

    // Same burger animation as LoginScreen.
    _burgerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    _burgerScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.72,
          end: 1.08,
        ).chain(
          CurveTween(
            curve: Curves.easeOutCubic,
          ),
        ),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.08,
          end: 0.98,
        ).chain(
          CurveTween(
            curve: Curves.easeOut,
          ),
        ),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.98,
          end: 1.0,
        ).chain(
          CurveTween(
            curve: Curves.easeOut,
          ),
        ),
        weight: 15,
      ),
    ]).animate(_burgerController);

    _burgerRotation = Tween<double>(
      begin: -0.045,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _burgerController,
        curve: Curves.easeOutBack,
      ),
    );

    _burgerOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _burgerController,
        curve: const Interval(
          0.0,
          0.45,
          curve: Curves.easeOut,
        ),
      ),
    );

    _burgerSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _burgerController,
        curve: Curves.easeOutBack,
      ),
    );

    _burgerController.forward();
  }

  // ============================================================
  // COUNTDOWN
  // ============================================================

  void _startCountdown() {
    _timer?.cancel();

    _remainingSeconds = 29;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_remainingSeconds <= 0) {
          timer.cancel();
          return;
        }

        setState(() {
          _remainingSeconds--;
        });
      },
    );
  }

  // ============================================================
  // OTP VALUE
  // ============================================================

  String get _otp {
    return _controllers
        .map((controller) => controller.text)
        .join();
  }

  bool get _isValid {
    return _otp.length == 6;
  }

  // ============================================================
  // OTP CHANGE
  // ============================================================

  void _onDigitChanged(
    String value,
    int index,
  ) {
    final digits = value.replaceAll(
      RegExp(r'\D'),
      '',
    );

    // Paste / multiple digits.
    if (digits.length > 1) {
      _applyCode(digits);
      return;
    }

    // Clean input.
    if (value != digits) {
      _controllers[index].value =
          TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(
          offset: digits.length,
        ),
      );
    }

    // Move forward.
    if (digits.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {});
  }

  // ============================================================
  // APPLY PASTED OTP
  // ============================================================

  void _applyCode(String code) {
    final digits = code
        .replaceAll(RegExp(r'\D'), '')
        .split('')
        .take(6)
        .toList();

    for (int i = 0; i < 6; i++) {
      _controllers[i].text =
          i < digits.length
              ? digits[i]
              : '';
    }

    setState(() {});

    if (digits.length == 6) {
      FocusScope.of(context).unfocus();
    } else if (digits.isNotEmpty) {
      _focusNodes[digits.length].requestFocus();
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

Future<void> _verifyOtp() async {
  if (!_isValid || isLoading) {
    return;
  }

  FocusScope.of(context).unfocus();

  setState(() {
    isLoading = true;
    _message = null;
  });

  try {
    final authService = AuthService();

    final login = await authService.verifyOtp(
      phone: widget.phone,
      otp: _otp,
      sessionId: widget.sessionId,
    );

    if (!mounted) return;

    // ==========================================================
    // EXISTING CUSTOMER
    // ==========================================================

    if (login != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );

      return;
    }

    // ==========================================================
    // NEW CUSTOMER
    // ==========================================================

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => NameScreen(
          phone: widget.phone,
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _message = e
          .toString()
          .replaceFirst('Exception: ', '');
    });
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

  Future<void> _resendOtp() async {
    if (_remainingSeconds > 0 || isLoading) {
      return;
    }

    try {
      final authService = AuthService();

      await authService.sendOtp(
        phone: widget.phone,
      );

      if (!mounted) return;

      for (final controller in _controllers) {
        controller.clear();
      }

      setState(() {
        _message = 'A new code has been sent.';
      });

      _startCountdown();

      _focusNodes[0].requestFocus();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _timer?.cancel();

    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final node in _focusNodes) {
      node.dispose();
    }

    _burgerController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final keyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        // Same transparent status bar as LoginScreen.
        statusBarColor: Colors.transparent,

        // White icons over the food hero.
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,

        // Cream navigation area.
        systemNavigationBarColor: cream,
        systemNavigationBarIconBrightness:
            Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: cream,
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        top: false,
        bottom: false,
        left: false,
        right: false,

        child: Column(
          children: [
            // ==================================================
            // HERO
            // ==================================================

            _buildHero(
              keyboardOpen: keyboardOpen,
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,

                padding: const EdgeInsets.fromLTRB(
                  32,
                  18,
                  32,
                  40,
                ),

                child: _buildContent(
                  keyboardOpen: keyboardOpen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // MATCHES LOGIN SCREEN SPACING / TYPOGRAPHY
  // ============================================================

  Widget _buildContent({
    required bool keyboardOpen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // TITLE
        // ======================================================

        Text(
          'Verify your number',

          style: GoogleFonts.bricolageGrotesque(
            fontSize: 32,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: ink,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        // ======================================================
        // DESCRIPTION
        // ======================================================

        Text.rich(
          TextSpan(
            style: GoogleFonts.sora(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w400,
              color: muted,
            ),

            children: [
              const TextSpan(
                text: 'We sent a 6-digit code to ',
              ),

              TextSpan(
                text: '+91 ${widget.phone}',

                style: GoogleFonts.sora(
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 24,
        ),

        // ======================================================
        // OTP LABEL
        // ======================================================

        Text(
          'ENTER OTP',

          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: ink,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // OTP BOXES
        // ======================================================

        _buildOtpRow(),

        // ======================================================
        // RESEND
        // ======================================================

        const SizedBox(
          height: 12,
        ),

        Row(
          children: [
            Text(
              "Didn't receive the OTP? ",

              style: GoogleFonts.sora(
                fontSize: 12,
                color: muted,
              ),
            ),

            TextButton(
              onPressed:
                  _remainingSeconds == 0 && !isLoading
                      ? _resendOtp
                      : null,

              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
              ),

              child: Text(
                _remainingSeconds == 0
                    ? 'Resend code'
                    : 'Resend in 0:${_remainingSeconds.toString().padLeft(2, '0')}',

                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: orange,
                ),
              ),
            ),
          ],
        ),

        // ======================================================
        // SAME LARGE LOGIN-SCREEN SPACING
        // ======================================================

        SizedBox(
          height: keyboardOpen ? 30 : 220,
        ),

        // ======================================================
        // VERIFY BUTTON
        // ======================================================

        _buildVerifyButton(),

        // ======================================================
        // MESSAGE
        // ======================================================

        SizedBox(
          height: _message == null ? 8 : 10,
        ),

        if (_message != null)
          Center(
            child: Text(
              _message!,
              textAlign: TextAlign.center,

              style: GoogleFonts.sora(
                fontSize: 12,
                color: orange,
              ),
            ),
          ),

        const SizedBox(
          height: 16,
        ),

        // ======================================================
        // LEGAL
        // ======================================================

        _buildLegalConsent(),
      ],
    );
  }

  // ============================================================
  // HERO
  // EXACT LOGIN-SCREEN HERO STRUCTURE
  // ============================================================

  Widget _buildHero({
    required bool keyboardOpen,
  }) {
    final double statusBarHeight =
        MediaQuery.of(context).padding.top;

    final double heroHeight =
        (keyboardOpen ? 220.0 : 250.0) +
            statusBarHeight;

    return SizedBox(
      width: double.infinity,

      // Same overflow space as LoginScreen.
      height: heroHeight + 25,

      child: Stack(
        clipBehavior: Clip.none,

        children: [
          // ====================================================
          // ORIGINAL LOGIN BACKGROUND
          // ====================================================

          Positioned(
            top: 0,
            left: 0,
            right: 0,

            child: SizedBox(
              height: heroHeight,

              child: ClipRRect(
                borderRadius:
                    const BorderRadius.only(
                  bottomLeft:
                      Radius.circular(40),
                  bottomRight:
                      Radius.circular(40),
                ),

                child: Image.asset(
                  'assets/images/otp_bg.png',

                  width: double.infinity,
                  height: heroHeight,

                  fit: BoxFit.cover,
                  alignment: Alignment.center,

                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      color: orange,
                    );
                  },
                ),
              ),
            ),
          ),

          // ====================================================
          // REBESTA BRAND PILL
          // SAME AS LOGIN
          // ====================================================

          Positioned(
            top: statusBarHeight + 5,
            left: 28,

            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(20),

                border: Border.all(
                  color: line,
                ),

                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),

              child: Row(
                mainAxisSize: MainAxisSize.min,

                children: [
                  SvgPicture.asset(
                    'assets/images/pizza.svg',

                    width: 16.2,
                    height: 16.2,

                    colorFilter:
                        const ColorFilter.mode(
                      orange,
                      BlendMode.srcIn,
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Text(
                    'reBesta',

                    style:
                        GoogleFonts
                            .bricolageGrotesque(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ====================================================
          // BURGER + CHEESE FOREGROUND
          // SAME AS LOGIN
          // ====================================================

          Positioned(
            left: -50,
            right: -25,
            bottom: -50,

            child: AnimatedBuilder(
              animation: _burgerController,

              builder: (
                context,
                child,
              ) {
                return Opacity(
                  opacity:
                      _burgerOpacity.value,

                  child: FractionalTranslation(
                    translation:
                        _burgerSlide.value,

                    child: Transform.rotate(
                      angle:
                          _burgerRotation.value,

                      child: Transform.scale(
                        scale:
                            _burgerScale.value,

                        alignment:
                            Alignment
                                .bottomCenter,

                        child: child,
                      ),
                    ),
                  ),
                );
              },

              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/pizza_foreground.png',

                  width: double.infinity,
                  height: 450,

                  fit: BoxFit.contain,
                  alignment:
                      Alignment.bottomCenter,

                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OTP ROW
  // ============================================================

  Widget _buildOtpRow() {
  return LayoutBuilder(
    builder: (context, constraints) {
      const double spacing = 8;

      final double boxWidth =
          (constraints.maxWidth - (spacing * 5)) / 6;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          6,
          (index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index == 5 ? 0 : spacing,
              ),
              child: SizedBox(
                width: boxWidth,
                height: 52,
                child: _buildOtpField(index),
              ),
            );
          },
        ),
      );
    },
  );
}
  // ============================================================
  // OTP FIELD
  // LOGIN-SCREEN VISUAL LANGUAGE
  // ============================================================

  Widget _buildOtpField(
    int index,
  ) {
    return SizedBox(
      width: 48,
      height: 52,

      child: Focus(
        onKeyEvent: (
          _,
          event,
        ) {
          if (event is KeyDownEvent &&
              event.logicalKey ==
                  LogicalKeyboardKey.backspace &&
              _controllers[index]
                  .text
                  .isEmpty &&
              index > 0) {
            _focusNodes[index - 1]
                .requestFocus();

            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },

        child: TextField(
          controller:
              _controllers[index],

          focusNode:
              _focusNodes[index],

          textAlign:
              TextAlign.center,

          keyboardType:
              TextInputType.number,

          textInputAction:
              index == 5
                  ? TextInputAction.done
                  : TextInputAction.next,

          maxLength: 1,

          inputFormatters: [
            FilteringTextInputFormatter
                .digitsOnly,
          ],

          onChanged: (
            value,
          ) {
            _onDigitChanged(
              value,
              index,
            );
          },

          onSubmitted: (_) {
            if (index == 5 && _isValid) {
              _verifyOtp();
            }
          },

          style: GoogleFonts.sora(
            fontSize: 20,
            fontWeight:
                FontWeight.w700,
            color: ink,
          ),

          decoration: InputDecoration(
            counterText: '',

            contentPadding:
                EdgeInsets.zero,

            filled: true,

            fillColor:
                Colors.white,

            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),

              borderSide:
                  const BorderSide(
                color: line,
                width: 1.5,
              ),
            ),

            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),

              borderSide:
                  const BorderSide(
                color: orange,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VERIFY BUTTON
  // SAME AS LOGIN BUTTON
  // ============================================================

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,

      child: ElevatedButton(
        onPressed:
            _isValid && !isLoading
                ? _verifyOtp
                : null,

        style:
            ElevatedButton.styleFrom(
          elevation: 0,

          backgroundColor:
              orange,

          foregroundColor:
              Colors.white,

          disabledBackgroundColor:
              const Color(0xFFE5E1DC),

          disabledForegroundColor:
              const Color(0xFF9B918C),

          shape:
              const StadiumBorder(),

          padding:
              EdgeInsets.zero,

          textStyle:
              GoogleFonts.sora(
            fontSize: 16,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,

                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [
                  Text(
                    'Verify',

                    style:
                        GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,

                      color:
                          _isValid
                              ? Colors.white
                              : const Color(
                                  0xFF9B918C,
                                ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Icon(
                    Icons
                        .arrow_forward_rounded,

                    size: 19,

                    color:
                        _isValid
                            ? Colors.white
                            : const Color(
                                0xFF9B918C,
                              ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // LEGAL CONSENT
  // SAME AS LOGIN SCREEN
  // ============================================================

  Widget _buildLegalConsent() {
    return Center(
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.sora(
            fontSize: 12,
            height: 1.4,
            fontWeight:
                FontWeight.w400,
            color: muted,
          ),

          children: [
            const TextSpan(
              text:
                  'By continuing, you agree to ',
            ),

            TextSpan(
              text: 'Terms',

              style:
                  GoogleFonts.sora(
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
                color: orange,
                decoration:
                    TextDecoration.underline,
                decorationColor:
                    orange,
              ),
            ),

            const TextSpan(
              text: ' and ',
            ),

            TextSpan(
              text: 'Policy',

              style:
                  GoogleFonts.sora(
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
                color: orange,
                decoration:
                    TextDecoration.underline,
                decorationColor:
                    orange,
              ),
            ),

            const TextSpan(
              text: '.',
            ),
          ],
        ),

        textAlign:
            TextAlign.center,
      ),
    );
  }
}

