import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/custom_image_widget.dart';

class OrderSummaryWidget extends StatelessWidget {
  final List<dynamic> items;
  final double totalAmount;
  final double discountAmount;
  final double deliveryFee;
  final String paymentStatus;
  final bool isExpanded;
  final VoidCallback onToggle;

  const OrderSummaryWidget({
    required this.items,
    required this.totalAmount,
    required this.discountAmount,
    required this.deliveryFee,
    required this.paymentStatus,
    required this.isExpanded,
    required this.onToggle,
    super.key,
  });

  double get _subtotal {
    double sum = 0;
    for (final item in items) {
      if (item is! Map) continue;
      final price = item['price'];
      final quantity = item['quantity'];
      final priceValue = price is num ? price.toDouble() : 0.0;
      final quantityValue = quantity is num ? quantity.toInt() : 0;
      sum += priceValue * quantityValue;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'receipt_long_rounded',
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${items.length} item${items.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: CustomIconWidget(
                      iconName: 'keyboard_arrow_down_rounded',
                      color: AppTheme.mutedText,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: isExpanded
                ? Column(
                    children: [
                      Divider(height: 1, color: AppTheme.outlineLight),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Column(
                          children: items.map<Widget>((rawItem) {
                            final item = rawItem is Map
                                ? Map<String, dynamic>.from(rawItem)
                                : <String, dynamic>{};

                            final menuItem = item['menu_items'];
                            final menu = menuItem is Map
                                ? Map<String, dynamic>.from(menuItem)
                                : <String, dynamic>{};

                            final name =
                                menu['name']?.toString() ?? 'Item';

                            final imageUrl =
                                menu['image_url']?.toString();

                            final quantity = item['quantity'];
                            final qty =
                                quantity is num ? quantity.toInt() : 1;

                            final price = item['price'];
                            final priceValue =
                                price is num ? price.toDouble() : 0.0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: (imageUrl == null ||
                                            imageUrl.isEmpty)
                                        ? Container(
                                            width: 48,
                                            height: 48,
                                            color: AppTheme
                                                .surfaceVariantLight,
                                            child: Icon(
                                              Icons.restaurant_rounded,
                                              size: 20,
                                              color: AppTheme.mutedText,
                                            ),
                                          )
                                        : CustomImageWidget(
                                            imageUrl: imageUrl,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            semanticLabel: name,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelMedium,
                                        ),
                                        Text(
                                          '×$qty',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${(priceValue * qty).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.headlineText,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: AppTheme.outlineLight,
                        indent: 16,
                        endIndent: 16,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Column(
                          children: [
                            _PriceRow(
                              label: 'Subtotal',
                              value: '₹${_subtotal.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 6),
                            _PriceRow(
                              label: 'Delivery fee',
                              value: '₹${deliveryFee.toStringAsFixed(2)}',
                            ),
                            if (discountAmount > 0) ...[
                              const SizedBox(height: 6),
                              _PriceRow(
                                label: 'Discount',
                                value:
                                    '-₹${discountAmount.toStringAsFixed(2)}',
                                valueColor: AppTheme.success,
                              ),
                            ],
                            const SizedBox(height: 10),
                            Divider(color: AppTheme.outlineLight),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Total Paid',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const Spacer(),
                                Text(
                                  '₹${totalAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariantLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  CustomIconWidget(
                                    iconName: 'account_balance_wallet_rounded',
                                    color: AppTheme.secondary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Payment',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: paymentStatus == 'paid'
                                          ? AppTheme.successContainer
                                          : AppTheme.warningContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      paymentStatus.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: paymentStatus == 'paid'
                                            ? const Color(0xFF16A34A)
                                            : AppTheme.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PriceRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.headlineText,
          ),
        ),
      ],
    );
  }
}