import 'package:flutter/material.dart';

class ProgressStepper extends StatelessWidget {
  final int step;
  final int totalSteps;

  const ProgressStepper({
    super.key,
    required this.step,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    double progress = step / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Step $step of $totalSteps",
          style: const TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation(
              Color(0xffFF5A1F),
            ),
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }
}