import 'dart:async';
import 'package:beelingual_app/app_UI/Exe_UI/topicExe.dart';
import 'package:beelingual_app/app_UI/Matches_UI/find_match_screen.dart';
import 'package:flutter/material.dart';
import 'package:beelingual_app/app_UI/home_UI/appTheme.dart';
import 'package:beelingual_app/connect_api/api_connect.dart';
import 'package:beelingual_app/app_UI/vocabulary_UI/topic_Vocab.dart';
import 'package:beelingual_app/app_UI/grammar_UI/grammarList.dart';
import 'package:beelingual_app/app_UI/Listening/ListeningLevel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _refreshTimer;
  final session = SessionManager();

  @override
  void initState() {
    super.initState();
    session.checkLoginStatus(context);
    _startAutoRefreshToken();
  }

  void _startAutoRefreshToken() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      final success = await session.refreshAccessToken();
      if (!success) {
        await session.logout(context);
      }
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      session.checkLoginStatus(context);
    });
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
          children: [Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.bgGradient,
            ),
          ),

            SafeArea(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                notificationPredicate: (notification) {
                  return notification.depth == 0;
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      /// HEADER
                      Text(
                        "Good day 👋",
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textDark.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "What will you learn today?",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),

                      const SizedBox(height: 28),

                      /// GRID MENU
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        childAspectRatio: 0.95,
                        children: [
                          _menuCard(
                            "Vocabulary",
                            Icons.menu_book_rounded,
                            AppTheme.cardGradients[0],
                                () => Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const LearningTopicsScreen()),
                            ),
                          ),
                          _menuCard(
                            "Grammar",
                            Icons.extension_rounded,
                            AppTheme.cardGradients[1],
                                () => Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const PageGrammarList()),
                            ),
                          ),
                          _menuCard(
                            "Exercises",
                            Icons.language_rounded,
                            AppTheme.cardGradients[2],
                                () => Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const PageTopicExercisesList()),
                            ),
                          ),
                          _menuCard(
                            "Listening",
                            Icons.headphones_rounded,
                            AppTheme.cardGradients[3],
                                () => Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      PageListeningLevel()),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      /// MOTIVATION - Animated Streak Card
                      _AnimatedStreakCard(),
                    ],
                  ),
                ),
              ),
            ),

          ]
      ),
    );
  }

  Widget _menuCard(
      String title,
      IconData icon,
      Gradient gradient,
      VoidCallback onTap,
      ) {
    return _AnimatedMenuCard(
      title: title,
      icon: icon,
      gradient: gradient,
      onTap: onTap,
    );
  }
}

// Animated Menu Card with scale and glow effects
class _AnimatedMenuCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _AnimatedMenuCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_AnimatedMenuCard> createState() => _AnimatedMenuCardState();
}

class _AnimatedMenuCardState extends State<_AnimatedMenuCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnim = Tween<double>(begin: 0.12, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  blurRadius: _isPressed ? 25 : 18,
                  offset: const Offset(0, 10),
                  color: Colors.black.withOpacity(_glowAnim.value),
                  spreadRadius: _isPressed ? 2 : 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                borderRadius: BorderRadius.circular(28),
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Stack(
                  children: [
                    // Background icon
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.2, end: _isPressed ? 0.35 : 0.2),
                        duration: const Duration(milliseconds: 200),
                        builder: (context, opacity, child) {
                          return Icon(
                            widget.icon,
                            size: 140,
                            color: Colors.white.withOpacity(opacity),
                          );
                        },
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon with subtle bounce
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1.0, end: _isPressed ? 1.15 : 1.0),
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.elasticOut,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Spacer(),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Animated Streak Card with Mascot (like TikTok)
class _AnimatedStreakCard extends StatefulWidget {
  @override
  State<_AnimatedStreakCard> createState() => _AnimatedStreakCardState();
}

class _AnimatedStreakCardState extends State<_AnimatedStreakCard>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _mascotController;
  late Animation<double> _glowAnim;
  late Animation<double> _bounceAnim;
  late Animation<double> _wobbleAnim;

  @override
  void initState() {
    super.initState();
    
    // Glow animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.1, end: 0.25).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Mascot bounce & wobble animation
    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _mascotController, curve: Curves.easeInOut),
    );

    _wobbleAnim = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _mascotController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _mascotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _mascotController]),
      builder: (context, child) {
        return Container(
          height: 120, // Increased height to prevent overflow
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.amber.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                blurRadius: 25,
                color: Colors.amber.withOpacity(_glowAnim.value),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 90, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        // Fire icon
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange.shade300, Colors.deepOrange],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Keep your streak!",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5D4037),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Luyện tập mỗi ngày 🔥",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Mascot (Bee) - positioned inside the card on the right
              Positioned(
                right: 15,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, _bounceAnim.value),
                    child: Transform.rotate(
                      angle: _wobbleAnim.value,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/Images/logoBee.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
