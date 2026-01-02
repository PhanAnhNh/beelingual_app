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

class _home_navigationState extends State<home_navigation> {
  int _selectedIndex = 0;

  final GlobalKey<NavigatorState> _homeNavigatorKey =
  GlobalKey<NavigatorState>();

  bool _dialogShowing = false;

  void switchToCompetition() {
    setState(() => _selectedIndex = 2);
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
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack();
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [

          /// MAIN SCAFFOLD
          Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              selectedItemColor: const Color(0xFF5D4037),
              unselectedItemColor: Colors.brown.shade300,
              backgroundColor: const Color(0xFFFFE082),
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                setState(() => _selectedIndex = index);
                if (index == 1) {
                  context.read<UserVocabularyProvider>()
                      .reloadVocab(context);
                }
              },
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded), label: "Home"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.menu_book), label: "Dictionary"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.assignment), label: "Translate"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: "Account"),
              ],
            ),
          ),

          /// 🔴 NÚT COMPETITION Ở GIỮA
          Positioned(
            bottom: 28, // 👈 chỉnh độ nhô lên
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FindMatchScreen(),
                  ),
                );
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.cardGradients[4],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.sports_mma,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );

  }
}