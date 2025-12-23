import 'dart:async';
import 'package:beelingual/app_UI/Exe_UI/topicExe.dart';
import 'package:flutter/material.dart';
import 'package:beelingual/app_UI/home_UI/appTheme.dart';
import 'package:beelingual/connect_api/api_connect.dart';
import 'package:beelingual/app_UI/vocabulary_UI/topic_Vocab.dart';
import 'package:beelingual/app_UI/grammar_UI/grammarList.dart';
import 'package:beelingual/app_UI/translation_UI/translation_Page.dart';
import 'package:beelingual/app_UI/Listening/ListeningLevel.dart';

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

                    /// MOTIVATION
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 20,
                            color: Colors.black.withOpacity(0.08),
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.local_fire_department,
                              color: Colors.orange, size: 40),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Keep your streak!\nPractice every day 🔥",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        ],
                      ),
                    )
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 10),
              color: Colors.black.withOpacity(0.12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(icon,
                  size: 140, color: Colors.white.withOpacity(0.2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 42, color: Colors.white),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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
