import 'package:flutter/material.dart';

class MenuSearchWidget extends StatelessWidget {
  final ValueChanged<String>? onChanged;

  const MenuSearchWidget({
    super.key,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
            hintText: "Search in menu...",
            contentPadding: EdgeInsets.only(top: 14),
          ),
        ),
      ),
    );
  }
}