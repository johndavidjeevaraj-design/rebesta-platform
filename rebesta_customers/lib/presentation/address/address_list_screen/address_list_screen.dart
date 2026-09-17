import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../models/address.dart';
import '../../../routes/app_routes.dart';
import '../../../services/address_service.dart';
import '../../../theme/app_theme.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() =>
      _AddressListScreenState();
}

class _AddressListScreenState
    extends State<AddressListScreen> {
  final AddressService _addressService =
      AddressService();

  List<Address> _addresses = [];

  bool _isLoading = true;
  bool _isError = false;

  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  // ============================================================
  // LOAD ADDRESSES
  // ============================================================

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final addresses =
          await _addressService.getAddresses();

      if (!mounted) return;

      setState(() {
        _addresses = addresses;

        if (addresses.isNotEmpty) {
          _selectedAddressId ??=
              addresses.first.id;
        }

        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'ADDRESS LOAD ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isError = true;
      });
    }
  }

  // ============================================================
  // SELECT ADDRESS
  // ============================================================

  void _selectAddress(Address address) {
    setState(() {
      _selectedAddressId = address.id;
    });

    // Return selected address to HomeScreen.
    context.pop(address);
  }

  // ============================================================
  // ADD ADDRESS
  // ============================================================

  Future<void> _addAddress() async {
    final result = await context.push(
      AppRoutes.addAddressScreen,
    );

    if (!mounted) return;

    // New address was created.
    if (result is Address) {
      setState(() {
        _addresses.insert(0, result);
        _selectedAddressId = result.id;
      });

      // Return newly created address to HomeScreen.
      context.pop(result);
      return;
    }

    // In case AddAddressScreen simply returns true.
    if (result == true) {
      await _loadAddresses();
    }
  }

  Future<void> _editAddress(Address address) async {
  final result = await context.push(
    AppRoutes.addAddressScreen,
    extra: address,
  );

  if (!mounted) return;

  if (result is Address) {
    setState(() {
      final index = _addresses.indexWhere(
        (item) => item.id == result.id,
      );

      if (index != -1) {
        _addresses[index] = result;
      }
    });
  } else if (result == true) {
    await _loadAddresses();
  }
}
Future<void> _confirmDelete(Address address) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppTheme.backgroundLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete address?',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.headlineText,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this saved address?',
          style: GoogleFonts.sora(
            fontSize: 13,
            color: AppTheme.mutedText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.sora(
                fontWeight: FontWeight.w700,
                color: AppTheme.headlineText,
              ),
            ),
          ),

          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.sora(
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  try {
    await _addressService.deleteAddress(
      addressId: address.id,
    );

    if (!mounted) return;

    setState(() {
      _addresses.removeWhere(
        (item) => item.id == address.id,
      );

      if (_selectedAddressId == address.id) {
        _selectedAddressId =
            _addresses.isNotEmpty
                ? _addresses.first.id
                : null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Address deleted',
          style: GoogleFonts.sora(),
        ),
      ),
    );
  } catch (e) {
    debugPrint('DELETE ADDRESS ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to delete address',
          style: GoogleFonts.sora(),
        ),
      ),
    );
  }
}

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.backgroundLight,

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            AppTheme.backgroundLight,

        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        title: Text(
          'Delivery address',
          style:
              GoogleFonts.bricolageGrotesque(
            fontSize: 21,
            fontWeight:
                FontWeight.w800,
            color:
                AppTheme.headlineText,
          ),
        ),

        centerTitle: false,
      ),

      body: _buildBody(),

      bottomNavigationBar:
          _buildAddButton(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_isError) {
      return _buildError();
    }

    if (_addresses.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAddresses,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          120,
        ),

        children: [
          Text(
            'Saved addresses',
            style:
                GoogleFonts.sora(
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
              color:
                  AppTheme.mutedText,
            ),
          ),

          const SizedBox(height: 12),

          ..._addresses.map(
            _buildAddressCard,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADDRESS CARD
  // ============================================================

  Widget _buildAddressCard(
    Address address,
  ) {
    final selected =
        _selectedAddressId ==
            address.id;

    return GestureDetector(
      onTap: () {
        _selectAddress(address);
      },

      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 180,
        ),

        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),

        padding:
            const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(18),

          border: Border.all(
            color: selected
                ? AppTheme.primary
                : const Color(
                    0xFFEAE5DF,
                  ),
            width:
                selected ? 1.8 : 1,
          ),

          boxShadow:
              AppTheme.cardShadow,
        ),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // ICON
            // ==================================================

            Container(
              width: 44,
              height: 44,

              decoration:
                  BoxDecoration(
                color: selected
                    ? AppTheme.primary
                        .withValues(
                        alpha: 0.10,
                      )
                    : const Color(
                        0xFFF7F3EE,
                      ),

                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),

              child: Icon(
                _getAddressIcon(
                  address.title,
                ),

                color:
                    selected
                        ? AppTheme.primary
                        : AppTheme
                            .headlineText,

                size: 21,
              ),
            ),

            const SizedBox(width: 14),

            // ==================================================
            // ADDRESS DETAILS
            // ==================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                 Row(
  children: [
    Expanded(
      child: Text(
        address.title,
        style: GoogleFonts.sora(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.headlineText,
        ),
      ),
    ),

    // EDIT BUTTON
    IconButton(
      onPressed: () {
        _editAddress(address);
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
      icon: Icon(
        Icons.edit_rounded,
        size: 18,
        color: AppTheme.primary,
      ),
    ),

    IconButton(
  onPressed: () {
    _confirmDelete(address);
  },
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(
    minWidth: 32,
    minHeight: 32,
  ),
  icon: const Icon(
    Icons.delete_outline_rounded,
    size: 18,
    color: Colors.redAccent,
  ),
),

    if (selected)
      Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          size: 14,
          color: Colors.white,
        ),
      ),
  ],
),

                  const SizedBox(height: 6),

                  Text(
                    address.address,
                    maxLines: 3,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        GoogleFonts.sora(
                      fontSize: 12,
                      height: 1.45,
                      color:
                          AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ADDRESS ICON
  // ============================================================

  IconData _getAddressIcon(
    String title,
  ) {
    final value =
        title.toLowerCase();

    if (value.contains('home')) {
      return Icons.home_rounded;
    }

    if (value.contains('work') ||
        value.contains('office')) {
      return Icons.work_rounded;
    }

    return Icons.location_on_rounded;
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 82,
              height: 82,

              decoration:
                  BoxDecoration(
                color: AppTheme.primary
                    .withValues(
                  alpha: 0.10,
                ),
                shape:
                    BoxShape.circle,
              ),

              child: Icon(
                Icons.location_on_rounded,
                size: 38,
                color:
                    AppTheme.primary,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'No address yet',
              style:
                  GoogleFonts.bricolageGrotesque(
                fontSize: 24,
                fontWeight:
                    FontWeight.w800,
                color:
                    AppTheme.headlineText,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Add your delivery address so we know where to bring your food.',
              textAlign:
                  TextAlign.center,

              style:
                  GoogleFonts.sora(
                fontSize: 13,
                height: 1.5,
                color:
                    AppTheme.mutedText,
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed:
                  _addAddress,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppTheme.primary,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape:
                    const StadiumBorder(),
              ),

              child: Text(
                'Add address',
                style:
                    GoogleFonts.sora(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            const Icon(
              Icons
                  .cloud_off_rounded,
              size: 46,
            ),

            const SizedBox(height: 16),

            Text(
              'Couldn’t load addresses',
              style:
                  GoogleFonts.sora(
                fontSize: 16,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Please check your connection and try again.',
              textAlign:
                  TextAlign.center,
              style:
                  GoogleFonts.sora(
                fontSize: 12,
                color:
                    AppTheme.mutedText,
              ),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed:
                  _loadAddresses,
              child:
                  const Text(
                'Try again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM ADD BUTTON
  // ============================================================

  Widget _buildAddButton() {
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          16,
        ),

        child: SizedBox(
          height: 54,
          width: double.infinity,

          child: ElevatedButton.icon(
            onPressed:
                _addAddress,

            icon: const Icon(
              Icons.add_rounded,
            ),

            label: Text(
              'Add new address',
              style:
                  GoogleFonts.sora(
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppTheme.primary,
              foregroundColor:
                  Colors.white,
              elevation: 0,
              shape:
                  const StadiumBorder(),
            ),
          ),
        ),
      ),
    );
  }
}