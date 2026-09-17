import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CartSummaryBarWidget
    extends StatelessWidget {
  final int itemCount;
  final double total;
  final VoidCallback onViewCart;
  final bool isEmbedded;

  const CartSummaryBarWidget({
    super.key,
    required this.itemCount,
    required this.total,
    required this.onViewCart,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    const orange =
        Color(0xFFF05C03);

    return Container(
      padding:
          EdgeInsets.fromLTRB(
        14,
        10,
        14,
        isEmbedded ? 10 : 20,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withAlpha(
              18,
            ),
            blurRadius: 18,
            offset:
                const Offset(0, -4),
          ),
        ],

        borderRadius:
            isEmbedded
                ? BorderRadius.circular(
                    15,
                  )
                : const BorderRadius.vertical(
                    top:
                        Radius.circular(
                      20,
                    ),
                  ),
      ),

      child:
          GestureDetector(
        onTap: onViewCart,

        child: Container(
          height: 52,

          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
          ),

          decoration:
              BoxDecoration(
            color: orange,

            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),

          child:
              Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white.withAlpha(
                    42,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    7,
                  ),
                ),

                child:
                    Text(
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'}',

                  style:
                      GoogleFonts.sora(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Colors.white,
                  ),
                ),
              ),

              const Spacer(),

              Text(
                'View Cart',

                style:
                    GoogleFonts.bricolageGrotesque(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Colors.white,
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              const Icon(
                Icons.arrow_forward_rounded,
                color:
                    Colors.white,
                size: 18,
              ),

              const Spacer(),

              Text(
                '₹${total.toStringAsFixed(2)}',

                style:
                    GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}