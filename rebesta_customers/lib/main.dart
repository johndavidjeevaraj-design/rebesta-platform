import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  //final prefs = await SharedPreferences.getInstance();
  //await prefs.remove('token');

  bool hasShownError = false;

  // ============================================================
  // GLOBAL ERROR HANDLING
  // ============================================================

  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      Future.delayed(
        const Duration(seconds: 5),
        () {
          hasShownError = false;
        },
      );

      return CustomErrorWidget(
        errorDetails: details,
      );
    }

    return const SizedBox.shrink();
  };

  // ============================================================
  // PORTRAIT ONLY
  // ============================================================

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // ============================================================
  // GO ROUTER
  // ============================================================

  GoRouter.optionURLReflectsImperativeAPIs = true;

  // ============================================================
  // START APP
  // ============================================================

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (
        context,
        orientation,
        screenType,
      ) {
        return MaterialApp.router(
          title: 'foodcustomer',

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,

          // ======================================================
          // TEXT SCALING
          // ======================================================

          builder: (
            context,
            child,
          ) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler:
                    const TextScaler.linear(1.0),
              ),
              child: child!,
            );
          },

          debugShowCheckedModeBanner: false,

          routerConfig: appRouter,
        );
      },
    );
  }
}