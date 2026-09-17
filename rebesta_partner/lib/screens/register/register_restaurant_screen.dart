import 'package:flutter/material.dart';

import '../../widgets/cuisine_chip.dart';

import '../dashboard/dashboard_screen.dart';

import '../../widgets/registration_header.dart';
import '../../widgets/progress_stepper.dart';
import '../../widgets/upload_image_card.dart';
import '../../widgets/section_card.dart';
import '../../widgets/app_textfield.dart';
import '../../widgets/app_button.dart';

class RegisterRestaurantScreen extends StatefulWidget {
  const RegisterRestaurantScreen({super.key});

  @override
  State<RegisterRestaurantScreen> createState() =>
      _RegisterRestaurantScreenState();
}

class _RegisterRestaurantScreenState
    extends State<RegisterRestaurantScreen> {

  final restaurantController = TextEditingController();

  final ownerController = TextEditingController();

  final phoneController = TextEditingController();

  final emailController = TextEditingController();

  final gstController = TextEditingController();

  final cuisineController = TextEditingController();

  final addressController = TextEditingController();

  final cityController = TextEditingController();

  final stateController = TextEditingController();

  final pincodeController = TextEditingController();

  final bankController = TextEditingController();

  final accountController = TextEditingController();

  final ifscController = TextEditingController();

  String restaurantType = "Both";

  List<String> selectedCuisine = [];

  @override
  void dispose() {

    restaurantController.dispose();
    ownerController.dispose();
    phoneController.dispose();
    emailController.dispose();
    gstController.dispose();
    cuisineController.dispose();

    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();

    bankController.dispose();
    accountController.dispose();
    ifscController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xffF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),

      body: SafeArea(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(24),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const RegistrationHeader(),

              const ProgressStepper(
                step: 1,
                totalSteps: 3,
              ),

              UploadImageCard(

                title: "Restaurant Logo",

                subtitle: "PNG / JPG • Maximum 5 MB",

                onTap: () {

                  // TODO Pick Logo

                },

              ),

              SectionCard(

                title: "Restaurant Details",

                icon: Icons.storefront_rounded,

                child: Column(

                  children: [

                    AppTextField(
                      controller: restaurantController,
                      hint: "Restaurant Name",
                    ),

                    const SizedBox(height: 18),

                    AppTextField(
                      controller: ownerController,
                      hint: "Owner Name",
                    ),

                    const SizedBox(height: 18),

                    AppTextField(
                      controller: phoneController,
                      hint: "Mobile Number",
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 18),

                    AppTextField(
                      controller: emailController,
                      hint: "Business Email",
                    ),

                    const SizedBox(height: 18),

                    AppTextField(
                      controller: gstController,
                      hint: "GST Number (Optional)",
                    ),

                  ],

                ),

              ),
                            SectionCard(

                title: "Restaurant Type",

                icon: Icons.restaurant_menu,

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(
                      "Restaurant Category",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 15),

 Wrap(
  spacing: 10,
  runSpacing: 10,
  children: [

    "South Indian",
    "North Indian",
    "Chinese",
    "Biryani",
    "Fast Food",
    "Juices",
    "Desserts",
    "Bakery"

  ].map((item){

    return CuisineChip(

      title: item,

      selected: selectedCuisine.contains(item),

      onTap: (){

        setState((){

          if(selectedCuisine.contains(item)){
            selectedCuisine.remove(item);
          }else{
            selectedCuisine.add(item);
          }

        });

      },

    );

  }).toList(),

),

                      

                    const SizedBox(height: 22),

                    AppTextField(

                      controller: cuisineController,

                      hint:
                          "Cuisine (Example: South Indian, Chinese)",

                    ),

                  ],

                ),

              ),

              SectionCard(

                title: "Restaurant Address",

                icon: Icons.location_on,

                child: Column(

                  children: [

                    AppTextField(
                      controller: addressController,
                      hint: "Full Address",
                    ),

                    const SizedBox(height: 18),

                    Row(

                      children: [

                        Expanded(

                          child: AppTextField(
                            controller: cityController,
                            hint: "City",
                          ),

                        ),

                        const SizedBox(width: 15),

                        Expanded(

                          child: AppTextField(
                            controller: stateController,
                            hint: "State",
                          ),

                        ),

                      ],

                    ),

                    const SizedBox(height: 18),

                    AppTextField(
                      controller: pincodeController,
                      hint: "Pincode",
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 22),

                    SizedBox(

                      width: double.infinity,

                      child: OutlinedButton.icon(

                        onPressed: () {

                          // TODO:
                          // Auto Detect Location

                        },

                        icon: const Icon(
                          Icons.my_location,
                          color: Color(0xffFF5A1F),
                        ),

                        label: const Text(

                          "Detect Current Location",

                          style: TextStyle(

                            color: Color(0xffFF5A1F),

                            fontFamily: "Poppins",

                            fontWeight: FontWeight.w600,

                          ),

                        ),

                        style: OutlinedButton.styleFrom(

                          minimumSize:
                              const Size(double.infinity, 55),

                          shape:
                              RoundedRectangleBorder(

                            borderRadius:
                                BorderRadius.circular(16),

                          ),

                        ),

                      ),

                    ),

                  ],

                ),

              ),
                            SectionCard(

                title: "Bank Details",

                icon: Icons.account_balance,

                child: Column(

                  children: [

                    AppTextField(
                      controller: bankController,
                      hint: "Bank Name",
                    ),

                    const SizedBox(height: 18),

                    AppTextField(
                      controller: accountController,
                      hint: "Account Number",
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 18),

                    AppTextField(
                      controller: ifscController,
                      hint: "IFSC Code",
                    ),

                  ],

                ),

              ),

              UploadImageCard(

                title: "Restaurant Photo",

                subtitle: "Front view of your restaurant",

                onTap: () {

                  // TODO:
                  // Pick Restaurant Image

                },

              ),

              const SizedBox(height: 15),

              SizedBox(

                width: double.infinity,

                child: AppButton(

                  text: "Continue",

                  onPressed: () {

                    Navigator.pushReplacement(

                      context,

                      MaterialPageRoute(

                        builder: (_) =>
                            const DashboardScreen(),

                      ),

                    );

                  },

                ),

              ),

              const SizedBox(height: 40),

            ],

          ),

        ),

      ),

    );

  }

}