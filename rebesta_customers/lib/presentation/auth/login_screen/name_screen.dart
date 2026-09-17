import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/auth_service.dart';
import '../../home_screen/home_screen.dart';

class NameScreen extends StatefulWidget {
  final String phone;

  const NameScreen({
    super.key,
    required this.phone,
  });

  @override
  State<NameScreen> createState() => _NameScreenState();
}


class _NameScreenState extends State<NameScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final TextEditingController _nameController =
      TextEditingController();

  void _onNameChanged() {
  setState(() {});
}

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = false;
  late AnimationController _burgerController;

  late Animation<double> _burgerScale;
  late Animation<double> _burgerRotation;
  late Animation<double> _burgerOpacity;
  late Animation<Offset> _burgerSlide;

  bool get _isValid {
    return _nameController.text.trim().length >= 2;
  }

  // ============================================================
  // COLORS — SAME AS LOGIN / OTP
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

  _nameController.addListener(_onNameChanged);

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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _burgerController.dispose();

    super.dispose();
  }

  // ============================================================
  // COMPLETE PROFILE
  // ============================================================

  Future<void> _continue() async {
    if (!_isValid || _isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();

      await authService.completeProfile(
        mobile: widget.phone,
        name: _nameController.text.trim(),
      );

      if (!mounted) return;

      // ========================================================
      // PROFILE CREATED
      // ========================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst(
                'Exception: ',
                '',
              ),
              style: GoogleFonts.sora(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final keyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    // ----------------------------------------------------------
    // STATUS BAR
    // ----------------------------------------------------------

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: cream,
        systemNavigationBarIconBrightness: Brightness.dark,
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
  // HERO
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

      // Same structure as LoginScreen.
      height: heroHeight + 25,

      child: Stack(
        clipBehavior: Clip.none,

        children: [

           Positioned(
          top: 0,
          left: 0,
          right: 0,

          child: SizedBox(
            height: heroHeight,

            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),

              child: Image.asset(
                'assets/images/name_bg.png',

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
          // BACKGROUND IMAGE
          // ====================================================

        Positioned(
  left: -35,
  right: -35,
  bottom: 20,

  child: AnimatedBuilder(
    animation: _burgerController,

    builder: (context, child) {
      return Opacity(
        opacity: _burgerOpacity.value,

        child: FractionalTranslation(
          translation: _burgerSlide.value,

          child: Transform.rotate(
            angle: _burgerRotation.value,

            child: Transform.scale(
              scale: _burgerScale.value,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        ),
      );
    },

    child: IgnorePointer(
      child: Image.asset(
        'assets/images/friedchicken_foreground.png',
        width: double.infinity,
        height: 385,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
      ),
    ),
  ),
),

          // ====================================================
          // REBESTA BRAND PILL
          // ====================================================

          Positioned(
            top: statusBarHeight + 5,
            left: 28,

            child: Container(
              padding:
                  const EdgeInsets.symmetric(
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
                mainAxisSize:
                    MainAxisSize.min,

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
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent({
    required bool keyboardOpen,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        // ======================================================
        // TITLE
        // ======================================================

        Text(
          "What's your name?",

          style:
              GoogleFonts.bricolageGrotesque(
            fontSize: 32,
            height: 1.1,
            fontWeight:
                FontWeight.w800,
            letterSpacing: -0.8,
            color: ink,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        // ======================================================
        // SUBTITLE
        // ======================================================

        Text(
          "Let's personalize your food journey. Tell us how we should address you.",

          style: GoogleFonts.sora(
            fontSize: 14,
            height: 1.4,
            fontWeight:
                FontWeight.w400,
            color: muted,
          ),
        ),

        const SizedBox(
          height: 28,
        ),

        // ======================================================
        // NAME LABEL
        // ======================================================

        Text(
          'YOUR NAME',

          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
            letterSpacing: 0.2,
            color: ink,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // NAME FIELD
        // ======================================================

        _buildNameField(),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // HELPER TEXT
        // ======================================================

        Text(
          'Just your name. You can add more details later.',

          style: GoogleFonts.sora(
            fontSize: 12,
            height: 1.4,
            fontWeight:
                FontWeight.w400,
            color: muted,
          ),
        ),

        // ======================================================
        // SPACE BEFORE BUTTON
        // ======================================================

        SizedBox(
          height: keyboardOpen
              ? 30
              : 250,
        ),

        // ======================================================
        // CONTINUE BUTTON
        // ======================================================

        _buildContinueButton(),

        const SizedBox(
          height: 20,
        ),
      ],
    );
  }

  // ============================================================
  // NAME FIELD
  // ============================================================

  Widget _buildNameField() {
    return Container(
      width: double.infinity,
      height: 52,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        border: Border.all(
          color: _isValid
              ? orange
              : line,

          width: _isValid
              ? 1.8
              : 1.5,
        ),

        borderRadius:
            BorderRadius.circular(26),
      ),

      child: Row(
        children: [
          // ====================================================
          // PERSON ICON
          // ====================================================

          Icon(
            Icons.person_outline_rounded,

            size: 21,

            color: _isValid
                ? orange
                : muted,
          ),

          const SizedBox(
            width: 12,
          ),

          // ====================================================
          // NAME INPUT
          // ====================================================

          Expanded(
            child: TextField(
              controller:
                  _nameController,

              autofocus: true,

              textCapitalization:
                  TextCapitalization.words,

              keyboardType:
                  TextInputType.name,

              textInputAction:
                  TextInputAction.done,

              onSubmitted: (_) {
                if (_isValid) {
                  _continue();
                }
              },

              style:
                  GoogleFonts.sora(
                fontSize: 14,
                fontWeight:
                    FontWeight.w500,
                color: ink,
              ),

              decoration:
                  const InputDecoration(
                border:
                    InputBorder.none,

                enabledBorder:
                    InputBorder.none,

                focusedBorder:
                    InputBorder.none,

                disabledBorder:
                    InputBorder.none,

                errorBorder:
                    InputBorder.none,

                focusedErrorBorder:
                    InputBorder.none,

                filled: false,

                hintText:
                    'Enter your name',

                contentPadding:
                    EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTINUE BUTTON
  // ============================================================

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,

      child: ElevatedButton(
        onPressed:
            _isValid && !_isLoading
                ? _continue
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
        ),

        child: _isLoading
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
                    "Let's go",

                    style:
                        GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,

                      color: _isValid
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

                    color: _isValid
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
}