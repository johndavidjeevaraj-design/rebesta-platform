import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/partner_menu_service.dart';
import '../../widgets/menu/upload_dish_image.dart';
import '../../widgets/menu/dish_information_card.dart';
import '../../widgets/menu/food_type_selector.dart';
import '../../widgets/menu/description_card.dart';
import '../../widgets/menu/special_setting_card.dart';

// ============================================================
// ADD / EDIT DISH
// ============================================================
//
// One screen, two modes:
// - dish == null  -> add a new dish
// - dish != null  -> edit an existing one (prefilled)
//
// Saving sends multipart/form-data so a newly picked photo
// travels with the same request. Pop returns true when the
// menu changed so the dashboard refreshes.
// ============================================================

class AddDishScreen extends StatefulWidget {
  final Map<String, dynamic>? dish;

  const AddDishScreen({super.key, this.dish});

  @override
  State<AddDishScreen> createState() => _AddDishScreenState();
}

class _AddDishScreenState extends State<AddDishScreen> {
  final dishNameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();

  String? category;

  String selectedFoodType = "Veg";

  bool available = true;

  bool _saving = false;

  // Newly picked photo (uploaded together with the dish)

  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _imageMimeType;

  // Existing photo (edit mode, unchanged)

  String? _existingImageUrl;

  bool get _isEdit => widget.dish != null;

  @override
  void initState() {
    super.initState();

    final dish = widget.dish;

    if (dish != null) {
      dishNameController.text =
          dish['name']?.toString() ?? '';

      final price = dish['price'];

      priceController.text = price is num
          ? (price == price.roundToDouble()
              ? price.round().toString()
              : price.toString())
          : '';

      category = dish['category']?.toString();

      descriptionController.text =
          dish['description']?.toString() ?? '';

      selectedFoodType =
          (dish['is_veg'] ?? dish['isVeg']) == true
              ? 'Veg'
              : 'Non Veg';

      available =
          (dish['is_available'] ?? dish['isAvailable']) ==
              true;

      _existingImageUrl =
          (dish['image_url'] ?? dish['imageUrl'])
              ?.toString();
    }
  }

  @override
  void dispose() {
    dishNameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // ==========================================================
  // PICK PHOTO (gallery or camera, compressed)
  // ==========================================================

  Future<void> _pickImage() async {
    final source =
        await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(
                ImageSource.gallery,
              ),
            ),

            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(
                ImageSource.camera,
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1400,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      setState(() {
        _imageBytes = bytes;
        _imageFileName = picked.name;
        _imageMimeType = picked.mimeType;
      });
    } catch (e) {
      debugPrint('IMAGE PICK ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not pick that image'),
        ),
      );
    }
  }

  // ==========================================================
  // SAVE
  // ==========================================================

  Future<void> _saveDish() async {
    final name = dishNameController.text.trim();

    final price =
        double.tryParse(priceController.text.trim());

    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the dish name'),
        ),
      );

      return;
    }

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price'),
        ),
      );

      return;
    }

    if (category == null || category!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a category'),
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (_isEdit) {
        await PartnerMenuService.updateDish(
          widget.dish!['id']?.toString() ?? '',
          name: name,
          price: price,
          category: category!,
          description: descriptionController.text.trim(),
          isVeg: selectedFoodType == 'Veg',
          isAvailable: available,
          imageBytes: _imageBytes,
          imageFileName: _imageFileName,
          imageMimeType: _imageMimeType,
        );
      } else {
        await PartnerMenuService.createDish(
          name: name,
          price: price,
          category: category!,
          description: descriptionController.text.trim(),
          isVeg: selectedFoodType == 'Veg',
          isAvailable: available,
          imageBytes: _imageBytes,
          imageFileName: _imageFileName,
          imageMimeType: _imageMimeType,
        );
      }

      if (!mounted) return;

      // Tell the dashboard to refresh
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  // ==========================================================
  // UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          _isEdit ? "Edit Dish" : "Add New Dish",
          style: const TextStyle(
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
              UploadDishImage(
                imageBytes: _imageBytes,
                imageUrl: _existingImageUrl,
                onPick: _pickImage,
              ),

              const SizedBox(height: 20),

              DishInformationCard(
                dishNameController: dishNameController,
                priceController: priceController,
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

              DescriptionCard(
                controller: descriptionController,
              ),

              const SizedBox(height: 20),

              SpecialSettingCard(
                available: available,
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
                  onPressed: _saving ? null : _saveDish,
                  child: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isEdit ? "Save Changes" : "Save Dish",
                          style: const TextStyle(
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
