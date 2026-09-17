import 'package:flutter/material.dart';

class DishInformationCard extends StatelessWidget {
  final TextEditingController dishNameController;
  final TextEditingController priceController;
  final TextEditingController prepTimeController;

  final String? category;
  final ValueChanged<String?> onCategoryChanged;

  const DishInformationCard({
    super.key,
    required this.dishNameController,
    required this.priceController,
    required this.prepTimeController,
    required this.category,
    required this.onCategoryChanged,
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
                "Dish Information",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                ),
              ),

            ],
          ),

          const SizedBox(height: 22),

          TextField(
            controller: dishNameController,
            decoration: InputDecoration(
              labelText: "Dish Name",
              prefixIcon: const Icon(Icons.fastfood),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,

            decoration: InputDecoration(
              labelText: "Price (£)",
              prefixIcon: const Icon(Icons.currency_pound),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 18),

          DropdownButtonFormField<String>(
            initialValue: category,

            decoration: InputDecoration(
              labelText: "Category",

              prefixIcon: const Icon(Icons.category),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),

            items: const [

              DropdownMenuItem(
                value: "Breakfast",
                child: Text("Breakfast"),
              ),

              DropdownMenuItem(
                value: "Lunch",
                child: Text("Lunch"),
              ),

              DropdownMenuItem(
                value: "Dinner",
                child: Text("Dinner"),
              ),

              DropdownMenuItem(
                value: "Chinese",
                child: Text("Chinese"),
              ),

              DropdownMenuItem(
                value: "Beverages",
                child: Text("Beverages"),
              ),

              DropdownMenuItem(
                value: "Desserts",
                child: Text("Desserts"),
              ),

            ],

            onChanged: onCategoryChanged,
          ),

          const SizedBox(height: 18),

          TextField(
            controller: prepTimeController,
            keyboardType: TextInputType.number,

            decoration: InputDecoration(
              labelText: "Preparation Time (Minutes)",
              prefixIcon: const Icon(Icons.timer),

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