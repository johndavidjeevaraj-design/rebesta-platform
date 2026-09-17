import 'package:flutter/material.dart';
import '../../screens/dashboard/pages/menu_dashboard.dart';
import '../../screens/dashboard/pages/order_dashboard.dart';
import '../../screens/dashboard/pages/reports_dashboard.dart';
import '../../screens/register/register_restaurant_screen.dart';

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

 Widget actionCard(
  BuildContext context,
  IconData icon,
  String title,
  Color color,
  VoidCallback onTap,
) {
  return Container(
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
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: .15),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontFamily: "Poppins",
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {

    return GridView.count(

      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      crossAxisCount: 2,

      crossAxisSpacing: 15,

      mainAxisSpacing: 15,

      childAspectRatio: 1.1,

      children: [

  actionCard(
    context,
    Icons.restaurant_menu,
    "Add Menu",
    Colors.deepOrange,
    () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MenuDashboard(),
        ),
      );
    },
  ),

  actionCard(
    context,
    Icons.receipt_long,
    "Orders",
    Colors.blue,
    () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OrderDashboard(),
        ),
      );
    },
  ),

  actionCard(
    context,
    Icons.store,
    "Restaurant",
    Colors.green,
    () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RegisterRestaurantScreen(),
        ),
      );
    },
  ),

  actionCard(
    context,
    Icons.bar_chart,
    "Reports",
    Colors.purple,
    () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ReportsDashboard(),
        ),
      );
    },
  ),
],
);

}


}