import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/delivery_api_client.dart';
import '../../core/storage/delivery_auth_storage.dart';
import 'package:dio/dio.dart';
import '../dashboard/delivery_dashboard_screen.dart';



class DeliveryLoginScreen extends StatefulWidget {
  const DeliveryLoginScreen({super.key});

  @override
  State<DeliveryLoginScreen> createState() =>
      _DeliveryLoginScreenState();
}

class _DeliveryLoginScreenState
    extends State<DeliveryLoginScreen> {

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('=================================');
      debugPrint('🚴 DELIVERY LOGIN');
      debugPrint('Email: $email');
      debugPrint('POST: ${ApiConstants.login}');
      debugPrint('=================================');

      final response =
          await DeliveryApiClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      debugPrint(
        'DELIVERY LOGIN STATUS: ${response.statusCode}',
      );

      debugPrint(
        'DELIVERY LOGIN RESPONSE: ${response.data}',
      );

      final data = response.data;

      if (data['success'] != true) {
        throw Exception(
          data['message'] ?? 'Login failed',
        );
      }

      final token = data['accessToken'];
      final partner = data['partner'];

      if (token == null ||
          token.toString().isEmpty) {
        throw Exception(
          'Login succeeded but access token is missing',
        );
      }

      if (partner == null ||
          partner['id'] == null) {
        throw Exception(
          'Login succeeded but partner ID is missing',
        );
      }

      await DeliveryAuthStorage.saveSession(
        token: token.toString(),
        deliveryPartnerId:
            partner['id'].toString(),
      );

      debugPrint('=================================');
      debugPrint('✅ DELIVERY LOGIN SUCCESS');
      debugPrint(
        'Partner ID: ${partner['id']}',
      );
      debugPrint('Token saved');
      debugPrint('=================================');

      if (!mounted) return;

     _showMessage(
  'Welcome ${partner['name'] ?? 'Delivery Partner'}',
);

await Future.delayed(
  const Duration(milliseconds: 500),
);

if (!mounted) return;

Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => const DeliveryDashboardScreen(),
  ),
);

      // Dashboard will be connected next.
   } on DioException catch (e) {
  debugPrint('=================================');
  debugPrint('❌ DELIVERY LOGIN DIO ERROR');
  debugPrint('STATUS: ${e.response?.statusCode}');
  debugPrint('RESPONSE: ${e.response?.data}');
  debugPrint('MESSAGE: ${e.message}');
  debugPrint('=================================');

  if (!mounted) return;

  final responseData = e.response?.data;

  String message = 'Login failed';

  if (responseData is Map) {
    message =
        responseData['message']?.toString() ??
        'Login failed';
  }

  _showMessage(message);
} catch (e) {
  debugPrint('❌ DELIVERY LOGIN UNKNOWN ERROR: $e');

  if (mounted) {
    _showMessage(
      'Something went wrong',
    );
  }
}
    
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8F2),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 430,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                children: [

                  // =================================================
                  // LOGO / HEADER
                  // =================================================

                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFFF6B35),
                      borderRadius:
                          BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Delivery Partner',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color(0xFF2A1D1A),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Sign in to manage your deliveries',
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          Color(0xFF756864),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // =================================================
                  // EMAIL
                  // =================================================

                  const Text(
                    'Email',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Color(0xFF2A1D1A),
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller:
                        _emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        InputDecoration(
                      hintText:
                          'Enter your email',
                      prefixIcon:
                          const Icon(
                        Icons.email_outlined,
                      ),
                      filled: true,
                      fillColor:
                          Colors.white,
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // PASSWORD
                  // =================================================

                  const Text(
                    'Password',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Color(0xFF2A1D1A),
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller:
                        _passwordController,
                    obscureText:
                        _obscurePassword,
                    textInputAction:
                        TextInputAction.done,
                    onSubmitted: (_) =>
                        _login(),
                    decoration:
                        InputDecoration(
                      hintText:
                          'Enter your password',
                      prefixIcon:
                          const Icon(
                        Icons.lock_outline,
                      ),
                      suffixIcon:
                          IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons
                                  .visibility_outlined
                              : Icons
                                  .visibility_off_outlined,
                        ),
                      ),
                      filled: true,
                      fillColor:
                          Colors.white,
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =================================================
                  // LOGIN BUTTON
                  // =================================================

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : _login,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xFFFF6B35,
                        ),
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
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Your account must be approved by admin before you can sign in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Color(0xFF756864),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}