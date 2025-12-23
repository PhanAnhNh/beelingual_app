import 'package:beelingual/app_UI/account/pageAccount.dart';
import 'package:beelingual/app_UI/translation_UI/translation_Page.dart';
import 'package:beelingual/app_UI/vocabulary_UI/Dictionary.dart';
import 'package:flutter/material.dart';
import 'home_page.dart'; // Đừng quên import file home_page

class home_navigation extends StatefulWidget {
  const home_navigation({super.key});

  @override
  State<home_navigation> createState() => _home_navigationState();
}

class _home_navigationState extends State<home_navigation> {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _homeNavigatorKey= GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      Navigator(
        key: _homeNavigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const HomePage(), // Trang gốc của tab này
          );
        },
      ),
      VocabularyLearnedScreen(), // Placeholder cho trang Book
      PageTranslate(),
      const ProfilePage(), // Placeholder cho trang Account
    ];
    return Scaffold(

      // 2. Body sẽ hiển thị Widget trong list dựa theo index đang chọn
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF5D4037),
        unselectedItemColor: Colors.brown.shade300,
        backgroundColor: const Color(0xFFFFE082),
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Dictionary"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Translate"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),

    );
  }
}