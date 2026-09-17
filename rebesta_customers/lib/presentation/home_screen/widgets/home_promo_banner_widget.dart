import 'dart:async';

import 'package:flutter/material.dart';

class HomePromoBannerWidget extends StatefulWidget {
  const HomePromoBannerWidget({
    super.key,
  });

  @override
  State<HomePromoBannerWidget> createState() =>
      _HomePromoBannerWidgetState();
}

class _HomePromoBannerWidgetState
    extends State<HomePromoBannerWidget> {
  final PageController _pageController =
      PageController();

  Timer? _timer;

  int _currentPage = 0;

  final List<_PromoBanner> _banners = const [
    _PromoBanner(
      title: 'Cravings deserve more',
      subtitle: 'Get delicious food delivered to your door',
      buttonText: 'Explore now',
      icon: '🍔',
    ),
    _PromoBanner(
      title: 'Good food. Great offers.',
      subtitle: 'Discover something delicious near you',
      buttonText: 'View offers',
      icon: '🔥',
    ),
    _PromoBanner(
      title: 'Something for every craving',
      subtitle: 'Fresh meals from your favorite restaurants',
      buttonText: 'Order now',
      icon: '🍕',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        if (!_pageController.hasClients) return;

        _currentPage++;

        if (_currentPage >= _banners.length) {
          _currentPage = 0;
        }

        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(
            milliseconds: 500,
          ),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        4,
      ),
      height: 145,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: PageView.builder(
          controller: _pageController,
          itemCount: _banners.length,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (
            context,
            index,
          ) {
            final banner = _banners[index];

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF7438),
                    Color(0xFFFF4D2F),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -18,
                    bottom: -25,
                    child: Container(
                      width: 125,
                      height: 125,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Positioned(
                    right: 22,
                    top: 25,
                    child: Text(
                      banner.icon,
                      style: const TextStyle(
                        fontSize: 65,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      18,
                      135,
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.title,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          banner.subtitle,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white
                                .withValues(alpha: 0.90),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),

                        const Spacer(),

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                          child: Text(
                            banner.buttonText,
                            style: const TextStyle(
                              color:
                                  Color(0xFFFF5735),
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    left: 20,
                    bottom: 10,
                    child: Row(
                      children: List.generate(
                        _banners.length,
                        (dotIndex) {
                          final active =
                              dotIndex ==
                                  _currentPage;

                          return AnimatedContainer(
                            duration:
                                const Duration(
                              milliseconds: 200,
                            ),
                            margin:
                                const EdgeInsets.only(
                              right: 5,
                            ),
                            width:
                                active ? 16 : 5,
                            height: 5,
                            decoration:
                                BoxDecoration(
                              color: Colors.white
                                  .withValues(
                                alpha:
                                    active ? 1 : 0.45,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PromoBanner {
  final String title;
  final String subtitle;
  final String buttonText;
  final String icon;

  const _PromoBanner({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.icon,
  });
}