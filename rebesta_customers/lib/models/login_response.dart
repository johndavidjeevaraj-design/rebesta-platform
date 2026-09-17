class LoginResponse {
  final bool success;
  final String token;
  final Customer customer;

  LoginResponse({
    required this.success,
    required this.token,
    required this.customer,
  });

  factory LoginResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return LoginResponse(
      success: json['success'] == true,
      token: json['token']?.toString() ?? '',
      customer: Customer.fromJson(
        Map<String, dynamic>.from(
          json['customer'] ?? {},
        ),
      ),
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String? email;
  final String mobile;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
  });

  factory Customer.fromJson(
    Map<String, dynamic> json,
  ) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString() ?? '',
    );
  }
}