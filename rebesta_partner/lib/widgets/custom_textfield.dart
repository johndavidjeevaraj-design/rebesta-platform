import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {

  final String hint;

  final TextInputType keyboardType;

  final TextEditingController controller;

  const CustomTextField({

    super.key,

    required this.hint,

    required this.controller,

    this.keyboardType = TextInputType.text,

  });

  @override
  Widget build(BuildContext context) {

    return TextField(

      controller: controller,

      keyboardType: keyboardType,

      decoration: InputDecoration(

        hintText: hint,

        filled: true,

        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(

          horizontal: 18,

          vertical: 18,

        ),

        border: OutlineInputBorder(

          borderRadius: BorderRadius.circular(16),

          borderSide: BorderSide.none,

        ),

      ),

    );

  }

}