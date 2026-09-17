import 'package:flutter/material.dart';

import '../../../core/services/partner_offers_service.dart';

class OffersDashboard extends StatefulWidget {
  const OffersDashboard({super.key});

  @override
  State<OffersDashboard> createState() => _OffersDashboardState();
}

class _OffersDashboardState extends State<OffersDashboard> {
  List<Map<String, dynamic>> _offers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  // ============================================================
  // LOAD OFFERS
  // ============================================================

  Future<void> _loadOffers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final offers =
          await PartnerOffersService.getPartnerOffers();

      if (!mounted) return;

      setState(() {
        _offers = offers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ============================================================
  // ADD OFFER
  // ============================================================

  Future<void> _showAddOfferSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OfferFormSheet(
        onSave: (data) async {
          await PartnerOffersService.createOffer(
            code: data.code,
            title: data.title,
            description: data.description,
            discountType: data.discountType,
            discountValue: data.discountValue,
            maxDiscount: data.maxDiscount,
            minOrderAmount: data.minOrderAmount,
            usageLimit: data.usageLimit,
  
            freeDelivery: data.freeDelivery,
          );
        },
      ),
    );

    if (result == true) {
      _loadOffers();
    }
  }

  // ============================================================
  // EDIT OFFER
  // ============================================================

  Future<void> _showEditOfferSheet(
    Map<String, dynamic> offer,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OfferFormSheet(
        offer: offer,
        onSave: (data) async {
          await PartnerOffersService.updateOffer(
            id: offer['id'].toString(),
            code: data.code,
            title: data.title,
            description: data.description,
            discountType: data.discountType,
            discountValue: data.discountValue,
            maxDiscount: data.maxDiscount,
            minOrderAmount: data.minOrderAmount,
            usageLimit: data.usageLimit,
            freeDelivery: data.freeDelivery,
            
          );
        },
      ),
    );

    if (result == true) {
      _loadOffers();
    }
  }

  // ============================================================
  // DEACTIVATE
  // ============================================================

  Future<void> _deactivateOffer(
    Map<String, dynamic> offer,
  ) async {
    final id = offer['id']?.toString();

    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate offer?'),
        content: Text(
          'Customers will no longer be able to apply ${offer['code']}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await PartnerOffersService.deactivateOffer(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer deactivated'),
        ),
      );

      _loadOffers();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  // ============================================================
  // ACTIVATE / DEACTIVATE
  // ============================================================

  Future<void> _toggleOffer(
    Map<String, dynamic> offer,
  ) async {
    final id = offer['id']?.toString();

    if (id == null || id.isEmpty) return;

    final currentActive =
        offer['is_active'] == true;

    try {
      await PartnerOffersService.updateOffer(
        id: id,
        isActive: !currentActive,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentActive
                ? 'Offer deactivated'
                : 'Offer activated',
          ),
        ),
      );

      _loadOffers();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F7F5),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF8F7F5),
        elevation: 0,
        title: const Text(
          'Offers',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading
                ? null
                : _loadOffers,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _showAddOfferSheet,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Add Offer',
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadOffers,
        child: _buildBody(theme),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          Icon(
            Icons.error_outline_rounded,
            size: 52,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Could not load offers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: _loadOffers,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Try Again',
              ),
            ),
          ),
        ],
      );
    }

    if (_offers.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 110),
          Container(
            width: 92,
            height: 92,
            margin:
                const EdgeInsets.symmetric(
              horizontal: 140,
            ),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_offer_rounded,
              size: 44,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 22),
          const Center(
            child: Text(
              'No offers yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 40,
              ),
              child: Text(
                'Create your first offer and make it visible to customers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: FilledButton.icon(
              onPressed: _showAddOfferSheet,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'Create Offer',
              ),
            ),
          ),
        ],
      );
    }

    final activeOffers = _offers
        .where(
          (offer) =>
              offer['is_active'] == true,
        )
        .toList();

    final inactiveOffers = _offers
        .where(
          (offer) =>
              offer['is_active'] != true,
        )
        .toList();

    return ListView(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        110,
      ),
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        _buildSummaryCard(
          activeOffers.length,
          _offers.length,
        ),

        const SizedBox(height: 22),

        if (activeOffers.isNotEmpty) ...[
          const _SectionHeader(
            title: 'Active Offers',
            icon: Icons.flash_on_rounded,
          ),
          const SizedBox(height: 10),
          ...activeOffers.map(
            (offer) => _buildOfferCard(
              offer,
              true,
            ),
          ),
        ],

        if (inactiveOffers.isNotEmpty) ...[
          const SizedBox(height: 22),
          const _SectionHeader(
            title: 'Inactive Offers',
            icon: Icons.pause_circle_outline_rounded,
          ),
          const SizedBox(height: 10),
          ...inactiveOffers.map(
            (offer) => _buildOfferCard(
              offer,
              false,
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCard(
    int activeCount,
    int totalCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF8A00),
            Color(0xFFFFB347),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Colors.orange.withAlpha(45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white
                  .withAlpha(45),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Restaurant Offers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$activeCount active · $totalCount total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OFFER CARD
  // ============================================================

  Widget _buildOfferCard(
    Map<String, dynamic> offer,
    bool active,
  ) {
    final code =
        offer['code']?.toString() ?? '';

    final title =
        offer['title']?.toString();

    final description =
        offer['description']?.toString();

    final discountType =
        offer['discount_type']?.toString() ??
            offer['discountType']?.toString() ??
            '';

    final discountValue =
        _toDouble(
          offer['discount_value'] ??
              offer['discountValue'],
        );

    final minOrder =
        _toDouble(
          offer['min_order_amount'] ??
              offer['minOrderAmount'],
        );

    final freeDelivery =
        offer['free_delivery'] == true ||
            offer['freeDelivery'] == true;

    final expiresAt =
        offer['expires_at']?.toString();

    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: active
              ? Colors.orange.shade100
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _offerIcon(
                  freeDelivery,
                  discountType,
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title?.isNotEmpty ==
                                      true
                                  ? title!
                                  : _discountLabel(
                                      discountType,
                                      discountValue,
                                      freeDelivery,
                                    ),
                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                          _statusChip(active),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Text(
                        code.toUpperCase(),
                        style: TextStyle(
                          color:
                              Colors.orange.shade800,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing: 1.1,
                          fontSize: 12,
                        ),
                      ),

                      if (description != null &&
                          description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (freeDelivery)
                  _infoPill(
                    Icons.delivery_dining_rounded,
                    'FREE DELIVERY',
                  )
                else
                  _infoPill(
                    Icons.percent_rounded,
                    _discountLabel(
                      discountType,
                      discountValue,
                      false,
                    ),
                  ),

                if (minOrder > 0)
                  _infoPill(
                    Icons.shopping_bag_outlined,
                    'Min ₹${_money(minOrder)}',
                  ),

                if (expiresAt != null &&
                    expiresAt.isNotEmpty)
                  _infoPill(
                    Icons.schedule_rounded,
                    'Ends ${_formatDate(expiresAt)}',
                  ),
              ],
            ),

            const SizedBox(height: 14),

            const Divider(height: 1),

            const SizedBox(height: 10),

            Row(
              children: [
                TextButton.icon(
                  onPressed: () =>
                      _showEditOfferSheet(
                    offer,
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                  ),
                  label: const Text(
                    'Edit',
                  ),
                ),

                const Spacer(),

                if (active)
                  TextButton.icon(
                    onPressed: () =>
                        _deactivateOffer(
                      offer,
                    ),
                    icon: const Icon(
                      Icons.pause_circle_outline,
                      size: 18,
                    ),
                    label: const Text(
                      'Deactivate',
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: () =>
                        _toggleOffer(
                      offer,
                    ),
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Activate',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OFFER ICON
  // ============================================================

  Widget _offerIcon(
    bool freeDelivery,
    String type,
  ) {
    IconData icon;

    if (freeDelivery) {
      icon = Icons.delivery_dining_rounded;
    } else if (type == 'percentage') {
      icon = Icons.percent_rounded;
    } else {
      icon = Icons.currency_rupee_rounded;
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: Colors.orange.shade700,
        size: 27,
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusChip(bool active) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.shade50
            : Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(30),
      ),
      child: Text(
        active ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          color: active
              ? Colors.green.shade700
              : Colors.grey.shade600,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: .6,
        ),
      ),
    );
  }

  // ============================================================
  // INFO PILL
  // ============================================================

  Widget _infoPill(
    IconData icon,
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(30),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _discountLabel(
    String type,
    double value,
    bool freeDelivery,
  ) {
    if (freeDelivery ||
        type == 'free_delivery') {
      return 'FREE DELIVERY';
    }

    if (type == 'percentage') {
      return '${_money(value)}% OFF';
    }

    return '₹${_money(value)} OFF';
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _money(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  String _formatDate(String value) {
    try {
      final date =
          DateTime.parse(value).toLocal();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }
}

// ==================================================================
// SECTION HEADER
// ==================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.orange.shade700,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// FORM DATA
// ==================================================================

class _OfferFormData {
  final String code;
  final String? title;
  final String? description;
  final String discountType;
  final double discountValue;
  final double? maxDiscount;
  final double? minOrderAmount;
  final int? usageLimit;
  final String? startsAt;
  final String? expiresAt;
  final bool freeDelivery;

  const _OfferFormData({
    required this.code,
    this.title,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    this.minOrderAmount,
    this.usageLimit,
    this.startsAt,
    this.expiresAt,
    required this.freeDelivery,
  });
}

// ==================================================================
// FORM SHEET
// ==================================================================

class _OfferFormSheet extends StatefulWidget {
  final Map<String, dynamic>? offer;
  final Future<void> Function(
    _OfferFormData data,
  ) onSave;

  const _OfferFormSheet({
    this.offer,
    required this.onSave,
  });

  @override
  State<_OfferFormSheet> createState() =>
      _OfferFormSheetState();
}

class _OfferFormSheetState
    extends State<_OfferFormSheet> {
  final _formKey =
      GlobalKey<FormState>();

  late final TextEditingController _codeController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _valueController;
  late final TextEditingController _maxDiscountController;
  late final TextEditingController _minOrderController;
  late final TextEditingController _usageLimitController;

  String _discountType = 'percentage';
  bool _freeDelivery = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final offer = widget.offer;

    _codeController =
        TextEditingController(
      text: offer?['code']?.toString() ?? '',
    );

    _titleController =
        TextEditingController(
      text: offer?['title']?.toString() ?? '',
    );

    _descriptionController =
        TextEditingController(
      text:
          offer?['description']?.toString() ??
              '',
    );

    _valueController =
        TextEditingController(
      text: offer?['discount_value']
              ?.toString() ??
          offer?['discountValue']
              ?.toString() ??
          '',
    );

    _maxDiscountController =
        TextEditingController(
      text: offer?['max_discount']
              ?.toString() ??
          offer?['maxDiscount']
              ?.toString() ??
          '',
    );

    _minOrderController =
        TextEditingController(
      text: offer?['min_order_amount']
              ?.toString() ??
          offer?['minOrderAmount']
              ?.toString() ??
          '',
    );

    _usageLimitController =
        TextEditingController(
      text: offer?['usage_limit']
              ?.toString() ??
          offer?['usageLimit']
              ?.toString() ??
          '',
    );

    final existingType =
        offer?['discount_type']
            ?.toString();

    if (existingType == 'flat' ||
        existingType == 'free_delivery') {
      _discountType = existingType!;
    }

    _freeDelivery =
        offer?['free_delivery'] == true ||
            offer?['freeDelivery'] == true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _maxDiscountController.dispose();
    _minOrderController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final value =
          double.tryParse(
        _valueController.text.trim(),
      ) ??
          0;

      final maxDiscount =
          double.tryParse(
        _maxDiscountController.text.trim(),
      );

      final minOrder =
          double.tryParse(
        _minOrderController.text.trim(),
      );

      final usageLimit =
          int.tryParse(
        _usageLimitController.text.trim(),
      );

      final data = _OfferFormData(
        code:
            _codeController.text.trim(),
        title:
            _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
        description:
            _descriptionController.text
                    .trim()
                    .isEmpty
                ? null
                : _descriptionController.text
                    .trim(),
        discountType:
            _discountType,
        discountValue:
            _freeDelivery
                ? 0
                : value,
        maxDiscount:
            maxDiscount,
        minOrderAmount:
            minOrder,
        usageLimit:
            usageLimit,
        freeDelivery:
            _freeDelivery,
      );

      await widget.onSave(data);

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            widget.offer == null
                ? 'Offer created successfully'
                : 'Offer updated successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
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
    final bottom =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    return Container(
      constraints:
          const BoxConstraints(
        maxHeight: 850,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                widget.offer == null
                    ? 'Create Offer'
                    : 'Edit Offer',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Control the promotion customers can use at your restaurant.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 24),

              _label('Offer Code'),

              TextFormField(
                controller:
                    _codeController,
                textCapitalization:
                    TextCapitalization.characters,
                decoration:
                    _decoration(
                  'Example: WELCOME20',
                  Icons.confirmation_number_outlined,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Enter an offer code';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              _label('Title'),

              TextFormField(
                controller:
                    _titleController,
                decoration:
                    _decoration(
                  'Example: 20% off your order',
                  Icons.title_rounded,
                ),
              ),

              const SizedBox(height: 16),

              _label('Description'),

              TextFormField(
                controller:
                    _descriptionController,
                maxLines: 2,
                decoration:
                    _decoration(
                  'Short customer-facing description',
                  Icons.notes_rounded,
                ),
              ),

              const SizedBox(height: 20),

              _label('Offer Type'),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _typeChip(
                    'percentage',
                    'Percentage OFF',
                    Icons.percent_rounded,
                  ),
                  _typeChip(
                    'flat',
                    '₹ OFF',
                    Icons.currency_rupee_rounded,
                  ),
                  _typeChip(
                    'free_delivery',
                    'Free Delivery',
                    Icons.delivery_dining_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              SwitchListTile.adaptive(
                contentPadding:
                    EdgeInsets.zero,
                title: const Text(
                  'Free delivery',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Remove the delivery fee when this offer is applied.',
                ),
                value: _freeDelivery,
                onChanged: (value) {
                  setState(() {
                    _freeDelivery = value;

                    if (value) {
                      _discountType =
                          'free_delivery';
                    } else {
                      _discountType =
                          'percentage';
                    }
                  });
                },
              ),

              if (!_freeDelivery) ...[
                const SizedBox(height: 8),

                _label(
                  _discountType == 'percentage'
                      ? 'Discount %'
                      : 'Discount Amount',
                ),

                TextFormField(
                  controller:
                      _valueController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      _decoration(
                    _discountType ==
                            'percentage'
                        ? 'Example: 20'
                        : 'Example: 100',
                    _discountType ==
                            'percentage'
                        ? Icons.percent_rounded
                        : Icons.currency_rupee_rounded,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter discount value';
                    }

                    final number =
                        double.tryParse(
                      value.trim(),
                    );

                    if (number == null ||
                        number < 0) {
                      return 'Enter a valid amount';
                    }

                    if (_discountType ==
                            'percentage' &&
                        number > 100) {
                      return 'Percentage cannot exceed 100';
                    }

                    return null;
                  },
                ),

                if (_discountType ==
                    'percentage') ...[
                  const SizedBox(height: 16),

                  _label(
                    'Maximum Discount',
                  ),

                  TextFormField(
                    controller:
                        _maxDiscountController,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    decoration:
                        _decoration(
                      'Optional',
                      Icons.savings_outlined,
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 16),

              _label(
                'Minimum Order Amount',
              ),

              TextFormField(
                controller:
                    _minOrderController,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    _decoration(
                  'Example: 299',
                  Icons.shopping_bag_outlined,
                ),
              ),

              const SizedBox(height: 16),

              _label('Usage Limit'),

              TextFormField(
                controller:
                    _usageLimitController,
                keyboardType:
                    TextInputType.number,
                decoration:
                    _decoration(
                  'Optional',
                  Icons.people_outline_rounded,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed:
                      _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.offer == null
                              ? 'CREATE OFFER'
                              : 'SAVE CHANGES',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TYPE CHIP
  // ============================================================

  Widget _typeChip(
    String value,
    String label,
    IconData icon,
  ) {
    final selected =
        _discountType == value;

    return ChoiceChip(
      selected: selected,
      label: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (_) {
        setState(() {
          _discountType = value;

          if (value ==
              'free_delivery') {
            _freeDelivery = true;
          } else {
            _freeDelivery = false;
          }
        });
      },
    );
  }

  Widget _label(String text) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  InputDecoration _decoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor:
          const Color(0xFFF8F7F5),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: BorderSide(
          color:
              Colors.orange.shade400,
          width: 1.5,
        ),
      ),
    );
  }
}