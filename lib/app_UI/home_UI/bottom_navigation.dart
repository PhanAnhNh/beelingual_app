import 'package:beelingual_app/app_UI/Matches_UI/find_match_screen.dart';
import 'package:beelingual_app/app_UI/account/pageAccount.dart';
import 'package:beelingual_app/app_UI/home_UI/appTheme.dart';
import 'package:beelingual_app/app_UI/translation_UI/translation_Page.dart';
import 'package:beelingual_app/app_UI/vocabulary_UI/Dictionary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../component/vocabularyProvider.dart';
import 'home_page.dart';

class home_navigation extends StatefulWidget {
  const home_navigation({super.key});

  static final GlobalKey<_home_navigationState> globalKey =
      GlobalKey<_home_navigationState>();

  @override
  State<home_navigation> createState() => _home_navigationState();
}

class _home_navigationState extends State<home_navigation>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  final GlobalKey<NavigatorState> _homeNavigatorKey =
      GlobalKey<NavigatorState>();

  bool _dialogShowing = false;

  // Animation controller for Arena button
  late AnimationController _arenaAnimController;
  late Animation<double> _arenaScaleAnim;

  late AnimationController _tabAnimController;
  late Animation<double> _tabBounceAnim;

  @override
  void initState() {
    super.initState();
    _arenaAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _arenaScaleAnim = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _arenaAnimController, curve: Curves.easeInOut),
    );

    _tabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _tabBounceAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tabAnimController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _arenaAnimController.dispose();
    _tabAnimController.dispose();
    super.dispose();
  }

  void switchToCompetition() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FindMatchScreen()),
    );
  }

  void goHome() {
    setState(() => _selectedIndex = 0);
  }

  void _showExitDialog() {
    if (_dialogShowing) return;
    _dialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Thoát ứng dụng"),
        content: const Text("Bạn có chắc chắn muốn thoát không?"),
        actions: [
          TextButton(
            onPressed: () {
              _dialogShowing = false;
              Navigator.of(context).pop();
            },
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              _dialogShowing = false;
              SystemNavigator.pop();
            },
            child: const Text(
              "Thoát",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBack() {
    if (_selectedIndex == 0 &&
        _homeNavigatorKey.currentState != null &&
        _homeNavigatorKey.currentState!.canPop()) {
      _homeNavigatorKey.currentState!.pop();
      return;
    }

    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return;
    }
    _showExitDialog();
  }

  int _getTabPosition(int navIndex) {
    if (navIndex < 2) return navIndex;
    return navIndex + 1;
  }

  void _onTabTap(int tabPosition) {
    int navIndex;
    if (tabPosition < 2) {
      navIndex = tabPosition;
    } else if (tabPosition > 2) {
      navIndex = tabPosition - 1;
    } else {
      return; // Center position is Arena button
    }

    if (navIndex != _selectedIndex) {
      _previousIndex = _selectedIndex;
      _tabAnimController.reset();
      _tabAnimController.forward();
    }

    setState(() => _selectedIndex = navIndex);
    if (navIndex == 1) {
      context.read<UserVocabularyProvider>().reloadVocab(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      Navigator(
        key: _homeNavigatorKey,
        onGenerateRoute: (_) =>
            MaterialPageRoute(builder: (_) => const HomePage()),
      ),
      VocabularyLearnedScreen(),
      PageTranslate(),
      const ProfilePage(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
        extendBody: true,
        bottomNavigationBar: _buildCustomBottomNav(),
      ),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Curved background
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 80),
            painter: _CurvedNavPainter(),
          ),

          // Navigation items
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_rounded, "Home"),
                _buildNavItem(1, Icons.menu_book_rounded, "Dictionary"),
                const SizedBox(width: 70), // Space for center button
                _buildNavItem(3, Icons.translate_rounded, "Translate"),
                _buildNavItem(4, Icons.person_rounded, "Account"),
              ],
            ),
          ),

          // Center Arena button
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTapDown: (_) => _arenaAnimController.forward(),
                onTapUp: (_) {
                  _arenaAnimController.reverse();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => FindMatchScreen()),
                  );
                },
                onTapCancel: () => _arenaAnimController.reverse(),
                child: ScaleTransition(
                  scale: _arenaScaleAnim,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF6B6B),
                          Color(0xFFE54A4A),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE54A4A).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.sports_mma,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int tabPosition, IconData icon, String label) {
    // Convert tab position to nav index for comparison
    int navIndex;
    if (tabPosition < 2) {
      navIndex = tabPosition;
    } else {
      navIndex = tabPosition - 1;
    }

    final isSelected = _selectedIndex == navIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTap(tabPosition),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _tabAnimController,
          builder: (context, child) {
            // Calculate bounce effect for newly selected item
            double bounceScale = 1.0;
            double bounceTranslateY = 0.0;

            if (isSelected && _tabAnimController.isAnimating) {
              // Bounce up effect
              bounceScale = 1.0 + (0.15 * _tabBounceAnim.value * (1 - _tabBounceAnim.value) * 4);
              bounceTranslateY = -8 * _tabBounceAnim.value * (1 - _tabBounceAnim.value) * 4;
            }

            return Transform.translate(
              offset: Offset(0, bounceTranslateY),
              child: Transform.scale(
                scale: bounceScale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon with animated background
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 16 : 12,
                        vertical: isSelected ? 8 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF5D4037).withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.9, end: isSelected ? 1.15 : 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? const Color(0xFF5D4037)
                                  : const Color(0xFF8D6E63),
                              size: 26,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Label with animation
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isSelected ? 1.0 : 0.6,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: isSelected ? 11 : 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected
                              ? const Color(0xFF5D4037)
                              : const Color(0xFF8D6E63),
                        ),
                        child: Text(label),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Custom painter for curved navigation background with notch
class _CurvedNavPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFE082) // Amber color matching app theme
      ..style = PaintingStyle.fill;

    // Shadow paint
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();

    // Notch parameters - more circular
    const notchRadius = 40.0; // Increased for rounder shape
    final centerX = size.width / 2;
    const topPadding = 0.0;

    // Start from bottom left
    path.moveTo(0, size.height);

    // Left side - straight up
    path.lineTo(0, topPadding);

    // Flat top until notch curve starts
    path.lineTo(centerX - notchRadius - 8, topPadding);

    // Smooth curve into circular notch
    path.quadraticBezierTo(
      centerX - notchRadius, topPadding,
      centerX - notchRadius, topPadding + notchRadius * 0.4,
    );

    // Main circular arc for the notch (larger, more circular)
    path.arcToPoint(
      Offset(centerX + notchRadius, topPadding + notchRadius * 0.4),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    // Smooth curve out of notch
    path.quadraticBezierTo(
      centerX + notchRadius, topPadding,
      centerX + notchRadius + 8, topPadding,
    );

    // Flat top to right edge
    path.lineTo(size.width, topPadding);

    // Right side down
    path.lineTo(size.width, size.height);

    // Close path
    path.close();

    // Draw shadow first
    canvas.drawPath(path.shift(const Offset(0, -2)), shadowPaint);

    // Draw the navigation bar
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}