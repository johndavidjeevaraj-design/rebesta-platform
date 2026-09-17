class ApiConstants {
  //static const String baseUrl = 'http://10.0.2.2:3000';
  static const String baseUrl = 'http://172.16.255.167:3000';

  static const String partnerAuth = '/partner-auth';

  static const String sendOtp =
      '$partnerAuth/send-otp';

  static const String verifyOtp =
      '$partnerAuth/verify-otp';

  static const String login =
      '$partnerAuth/login';

  static const String me =
      '$partnerAuth/me';

  static const String partnerOrders =
      '/partner-orders';
}