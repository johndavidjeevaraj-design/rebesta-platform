import 'package:flutter/material.dart';

import '../../widgets/menu/upload_dish_image.dart';
import '../../widgets/menu/dish_information_card.dart';
import '../../widgets/menu/food_type_selector.dart';
import '../../widgets/menu/spice_level_selector.dart';
import '../../widgets/menu/description_card.dart';
import '../../widgets/menu/ingredients_card.dart';
import '../../widgets/menu/special_setting_card.dart';

class AddDishScreen extends StatefulWidget {
  const AddDishScreen({super.key});

  @override
  State<AddDishScreen> createState() => _AddDishScreenState();
}

class _AddDishScreenState extends State<AddDishScreen> {
  final dishNameController = TextEditingController();
  final priceController = TextEditingController();
  final prepTimeController = TextEditingController();
  final descriptionController = TextEditingController();
  final ingredientsController = TextEditingController();

  String? category;

  String selectedFoodType = "Veg";
  String selectedSpice = "🌶 Medium";

  bool bestseller = false;
  bool available = true;

  @override
  void dispose() {
    dishNameController.dispose();
    priceController.dispose();
    prepTimeController.dispose();
    descriptionController.dispose();
    ingredientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Add New Dish",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [

              const UploadDishImage(),

              const SizedBox(height: 20),

              DishInformationCard(
                dishNameController: dishNameController,
                priceController: priceController,
                prepTimeController: prepTimeController,
                category: category,
                onCategoryChanged: (value) {
                  setState(() {
                    category = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              FoodTypeSelector(
                selectedType: selectedFoodType,
                onChanged: (value) {
                  setState(() {
                    selectedFoodType = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              SpiceLevelSelector(
                selectedLevel: selectedSpice,
                onChanged: (value) {
                  setState(() {
                    selectedSpice = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              DescriptionCard(
                controller: descriptionController,
              ),

              const SizedBox(height: 20),

              IngredientsCard(
                controller: ingredientsController,
              ),

              const SizedBox(height: 20),

SpecialSettingCard(
  bestseller: bestseller,
  available: available,
  onBestSellerChanged: (value) {
    setState(() {
      bestseller = value;
    });
  },
  onAvailableChanged: (value) {
    setState(() {
      available = value;
    });
  },
),

const SizedBox(height: 30),

SizedBox(
  width: double.infinity,
  height: 58,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xffFF5A1F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    onPressed: () {
      // TODO: Save to Node.js API
    },
    child: const Text(
      "Save Dish",
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),

const SizedBox(height: 50),

            ],
          ),
        ),
      ),
    );
  }
}