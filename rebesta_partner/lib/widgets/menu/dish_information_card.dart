import 'package:flutter/material.dart';

class DishInformationCard extends StatelessWidget {
  final TextEditingController dishNameController;
  final TextEditingController priceController;

  final String? category;
  final ValueChanged<String?> onCategoryChanged;

  const DishInformationCard({
    super.key,
    required this.dishNameController,
    required this.priceController,
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
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),

            decoration: InputDecoration(
              labelText: "Price (₹)",
              prefixIcon: const Icon(Icons.currency_rupee),

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

              // Dish types - these match what customers
              // tap as cravings on the customer app home

              DropdownMenuItem(
                value: "Biriyani",
                child: Text("Biriyani"),
              ),

              DropdownMenuItem(
                value: "Pizzas",
                child: Text("Pizzas"),
              ),

              DropdownMenuItem(
                value: "Burgers",
                child: Text("Burgers"),
              ),

              DropdownMenuItem(
                value: "Rolls",
                child: Text("Rolls"),
              ),

              DropdownMenuItem(
                value: "Shawarma",
                child: Text("Shawarma"),
              ),

              DropdownMenuItem(
                value: "Dosa",
                child: Text("Dosa"),
              ),

              DropdownMenuItem(
                value: "Idli",
                child: Text("Idli"),
              ),

              DropdownMenuItem(
                value: "Noodles",
                child: Text("Noodles"),
              ),

              DropdownMenuItem(
                value: "Cakes",
                child: Text("Cakes"),
              ),

              DropdownMenuItem(
                value: "Ice Cream",
                child: Text("Ice Cream"),
              ),

              // Meal types

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

        ],
      ),
    );
  }
}