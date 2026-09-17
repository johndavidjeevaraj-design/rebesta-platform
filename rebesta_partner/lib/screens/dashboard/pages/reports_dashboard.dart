import 'package:flutter/material.dart';

class ReportsDashboard extends StatelessWidget {
  const ReportsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Reports",
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}