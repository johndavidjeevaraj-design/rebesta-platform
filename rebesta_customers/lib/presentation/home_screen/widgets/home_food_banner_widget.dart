import 'package:flutter/material.dart';

class HomeFoodBannerWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final String? imageUrl;
  final VoidCallback? onTap;

  const HomeFoodBannerWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    this.imageUrl,
    this.onTap,
  });

  @override
  State<HomeFoodBannerWidget> createState() =>
      _HomeFoodBannerWidgetState();
}

class _HomeFoodBannerWidgetState
    extends State<HomeFoodBannerWidget>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          4,
        ),
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF7A3D),
              Color(0xFFFF4F2F),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.10,
              ),
              blurRadius: 18,
              offset: const Offset(
                0,
                8,
              ),
            ),
          ],
        ),
        child: Stack(
          children: [

            // Decorative circles
            Positioned(
              right: -35,
              top: -35,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.08,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              right: 35,
              bottom: -50,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.06,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                14,
                16,
              ),
              child: Row(
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [

                        Text(
                          widget.title,
                          maxLines: 2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight:
                                FontWeight.w800,
                            height: 1.1,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            color: Colors.white
                                .withValues(
                              alpha: 0.88,
                            ),
                            fontSize: 12.5,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 14),

                        GestureDetector(
  onTap: widget.onTap,
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 13,
      vertical: 7,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      widget.buttonText,
      style: const TextStyle(
        color: Color(0xFFFF5735),
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
),
                      ],
                    ),
                  ),

                  // Food visual
                  Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child:  Center(
                      child: ClipOval(
  child: Image.network(
    widget.imageUrl ?? '',
    width: 105,
    height: 105,
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) {
      return const Center(
        child: Text(
          '🍕',
          style: TextStyle(fontSize: 68),
        ),
      );
    },
  ),
)
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
}