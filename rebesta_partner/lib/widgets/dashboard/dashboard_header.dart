import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final String restaurantName;

  const DashboardHeader({
    super.key,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xffFF5A1F),
            Color(0xffFF7A00),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),

      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Good Morning 👋",
              style: TextStyle(
                color: Colors.white70,
                fontFamily: "Poppins",
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              restaurantName,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: "Poppins",
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [

                Container(
                  width: 12,
                  height: 12,

                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 10),

                const Text(
                  "Restaurant Open",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w600,
                  ),
                ),

              ],
            ),

          ],
        ),
      ),
    );
  }
}