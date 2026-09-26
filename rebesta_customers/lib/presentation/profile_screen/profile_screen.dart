import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/customer.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/delivery_socket_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';

// ============================================================
// PROFILE SCREEN
// ============================================================
//
// Shows the signed-in customer's profile. Only the name is
// editable - the mobile number is the OTP login identity
// and can never be changed from the app.
// ============================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();

  Customer? _customer;

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getProfile();

      if (!mounted) return;

      setState(() {
        _customer = profile;

        _loading = false;
      });
    } catch (e) {
      debugPrint('PROFILE LOAD ERROR: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  // ==========================================================
  // EDIT NAME
  // ==========================================================

  Future<void> _editName() async {
    if (_customer == null) return;

    final controller = TextEditingController(
      text: _customer!.name,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Edit name',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(
              controller.text.trim(),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    // null = cancelled, keep quiet
    if (newName == null || !mounted) return;

    if (newName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid name'),
        ),
      );

      return;
    }

    try {
      final updated = await _profileService.updateProfile(
        name: newName,
      );

      if (!mounted) return;

      setState(() {
        _customer = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      debugPrint('PROFILE UPDATE ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update profile'),
        ),
      );
    }
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Log out?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'You will need to log in again with your mobile number.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () =>
                Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Clear the stored session + drop any live socket
    await AuthService().logout();

    DeliverySocketService().disconnect();

    if (!mounted) return;

    context.go(AppRoutes.loginScreen);
  }

  // ==========================================================
  // UI
  // ==========================================================

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool locked = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (locked)
            const Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: AppTheme.mutedText,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _customer?.name ?? '';

    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ==================================================
                // AVATAR
                // ==================================================

                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary,
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Center(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // DETAILS
                // ==================================================

                _infoRow(
                  Icons.person_outline_rounded,
                  'Name',
                  name,
                ),

                const SizedBox(height: 12),

                _infoRow(
                  Icons.mail_outline_rounded,
                  'Email',
                  _customer?.email ?? '-',
                ),

                const SizedBox(height: 12),

                _infoRow(
                  Icons.phone_iphone_rounded,
                  'Mobile',
                  _customer?.mobile ?? '-',
                  locked: true,
                ),

                const SizedBox(height: 24),

                // ==================================================
                // EDIT
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed:
                        _customer == null ? null : _editName,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text(
                      'Edit Name',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // LOGOUT
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 20,
                    ),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      "Your mobile number can't be changed - it's your login.",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
