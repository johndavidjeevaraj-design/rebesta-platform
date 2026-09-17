import 'package:flutter/material.dart';

class IngredientsCard extends StatelessWidget {
  final TextEditingController controller;

  const IngredientsCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Row(
            children: [

              Icon(
                Icons.restaurant_menu,
                color: Color(0xffFF5A1F),
              ),

              SizedBox(width: 10),

              Text(
                "Ingredients",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                ),
              ),

            ],
          ),

          const SizedBox(height: 20),

          TextField(
            controller: controller,
            maxLines: 5,

            decoration: InputDecoration(
              hintText:
                  "Chicken, Rice, Pepper, Butter...",

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),

        ],
      ),
    );
  }
}