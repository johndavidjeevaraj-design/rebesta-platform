import 'package:flutter/material.dart';

class RecentOrderTile extends StatelessWidget {
  final String orderId;
  final String item;
  final String status;

  const RecentOrderTile({
    super.key,
    required this.orderId,
    required this.item,
    required this.status,
  });

  Color get statusColor {
    switch (status) {
      case "Preparing":
        return Colors.orange;
      case "Ready":
        return Colors.green;
      case "Delivered":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [

          CircleAvatar(
            radius: 24,
            backgroundColor: statusColor.withValues(alpha: .15),
            child: Icon(
              Icons.receipt_long,
              color: statusColor,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  orderId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: "Poppins",
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  item,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontFamily: "Poppins",
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),

            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(30),
            ),

            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontFamily: "Poppins",
              ),
            ),
          ),

        ],
      ),
    );
  }
}