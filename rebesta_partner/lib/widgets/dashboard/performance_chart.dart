import 'package:flutter/material.dart';

class PerformanceChart extends StatelessWidget {
  const PerformanceChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Today's Performance",
              style: TextStyle(
                fontFamily: "Poppins",
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 25),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                children: const [

                  _Bar(40),
                  _Bar(80),
                  _Bar(55),
                  _Bar(120),
                  _Bar(70),
                  _Bar(140),
                  _Bar(95),

                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;

  const _Bar(this.height);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,

      children: [

        Container(
          width: 22,
          height: height,

          decoration: BoxDecoration(
            color: const Color(0xffFF5A1F),
            borderRadius: BorderRadius.circular(20),
          ),
        ),

      ],
    );
  }
}