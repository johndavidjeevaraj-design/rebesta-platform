import 'package:flutter/material.dart';

class RegistrationHeader extends StatelessWidget {
  const RegistrationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),

        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: const Color(0xffFFF3ED),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: Color(0xffFF5A1F),
            size: 42,
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          "Complete Your Restaurant",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "Poppins",
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Let's setup your restaurant in just a few steps.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "Poppins",
            color: Colors.grey.shade600,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }
}