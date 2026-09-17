class Customer {
  final String id;
  final String name;
  final String email;
  final String mobile;

  const Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
    );
  }
}