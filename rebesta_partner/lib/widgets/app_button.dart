import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,

      child: ElevatedButton(

        onPressed: isLoading ? null : onPressed,

        style: ElevatedButton.styleFrom(

          backgroundColor: const Color(0xffFF5A1F),

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

        ),

        child: isLoading

            ? const SizedBox(

                width: 24,
                height: 24,

                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),

              )

            : Text(

                text,

                style: const TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),

              ),

      ),
    );
  }
}