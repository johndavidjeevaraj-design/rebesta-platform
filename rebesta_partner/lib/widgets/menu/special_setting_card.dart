import 'package:flutter/material.dart';

class SpecialSettingCard extends StatelessWidget {
  final bool bestseller;
  final bool available;

  final ValueChanged<bool> onBestSellerChanged;
  final ValueChanged<bool> onAvailableChanged;

  const SpecialSettingCard({
    super.key,
    required this.bestseller,
    required this.available,
    required this.onBestSellerChanged,
    required this.onAvailableChanged,
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
                Icons.star_rounded,
                color: Color(0xffFF5A1F),
              ),

              SizedBox(width: 10),

              Text(
                "Special Settings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

            ],
          ),

          const SizedBox(height: 20),

          SwitchListTile(
            value: bestseller,
            activeThumbColor: const Color(0xffFF5A1F),
            title: const Text("⭐ Bestseller"),
            subtitle: const Text("Show this dish as a bestseller"),
            onChanged: onBestSellerChanged,
          ),

          const Divider(),

          SwitchListTile(
            value: available,
            activeThumbColor: const Color(0xffFF5A1F),
            title: const Text("Available"),
            subtitle: const Text("Customers can order this dish"),
            onChanged: onAvailableChanged,
          ),

        ],
      ),
    );
  }
}