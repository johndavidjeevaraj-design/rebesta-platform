import 'package:flutter/material.dart';

import '../../../../services/order_service.dart';

// ============================================================
// REVIEW NUDGE SHEET
// ============================================================
//
// Shown once when the order lands on the customer's tracking
// screen as delivered. Restaurant rating is required, rider
// rating + comment are optional. Posts to /reviews.
// ============================================================

class ReviewNudgeSheet extends StatefulWidget {
  final String orderId;

  final String restaurantName;

  final String? riderName;

  const ReviewNudgeSheet({
    super.key,
    required this.orderId,
    required this.restaurantName,
    required this.riderName,
  });

  @override
  State<ReviewNudgeSheet> createState() =>
      _ReviewNudgeSheetState();
}

class _ReviewNudgeSheetState
    extends State<ReviewNudgeSheet> {
  final OrderService _orderService = OrderService();

  final TextEditingController _commentController =
      TextEditingController();

  int _restaurantRating = 0;

  int _deliveryRating = 0;

  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();

    super.dispose();
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submit() async {
    if (_restaurantRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please rate the restaurant first',
          ),
        ),
      );

      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await _orderService.submitReview(
        orderId: widget.orderId,
        restaurantRating: _restaurantRating,
        deliveryRating: _deliveryRating > 0
            ? _deliveryRating
            : null,
        review: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Thanks for your review!'),
        ),
      );
    } catch (e) {
      debugPrint(
        '❌ REVIEW SUBMIT ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _submitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not submit the review - please try again',
          ),
        ),
      );
    }
  }

  // ============================================================
  // STAR ROW
  // ============================================================

  Widget _starRow(
    String label,
    int rating,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2A2D34),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            final star = index + 1;

            return IconButton(
              onPressed: () => onChanged(star),
              padding: const EdgeInsets.symmetric(
                horizontal: 2,
              ),
              constraints: const BoxConstraints(),
              icon: Icon(
                star <= rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: const Color(0xFFFFB800),
                size: 34,
              ),
            );
          }),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================================================
          // HEADER
          // ================================================

          Row(
            children: [
              const Text(
                '🎉',
                style: TextStyle(fontSize: 26),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'How was your order?',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2A2D34),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ================================================
          // RESTAURANT RATING (required)
          // ================================================

          _starRow(
            'Rate ${widget.restaurantName}',
            _restaurantRating,
            (value) {
              setState(() {
                _restaurantRating = value;
              });
            },
          ),

          // ================================================
          // RIDER RATING (optional)
          // ================================================

          if (widget.riderName != null) ...[
            const SizedBox(height: 12),
            _starRow(
              'Rate ${widget.riderName} (your rider)',
              _deliveryRating,
              (value) {
                setState(() {
                  _deliveryRating = value;
                });
              },
            ),
          ],

          const SizedBox(height: 16),

          // ================================================
          // COMMENT (optional)
          // ================================================

          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Tell us more (optional)',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ================================================
          // ACTIONS
          // ================================================

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Submit Review',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _submitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text(
                'Maybe later',
                style: TextStyle(
                  color: Color(0xFF756864),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
