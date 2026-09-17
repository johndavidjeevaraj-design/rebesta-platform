import 'package:flutter/material.dart';

class DescriptionCard extends StatelessWidget {
  final TextEditingController controller;

  const DescriptionCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Row(
            children: [

              Icon(
                Icons.description_outlined,
                color: Color(0xffFF5A1F),
              ),

              SizedBox(width: 10),

              Text(
                "Description",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

            ],
          ),

          const SizedBox(height: 18),

          TextField(
            controller: controller,
            maxLines: 5,

            decoration: InputDecoration(
              hintText: "Tell customers about this dish...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
