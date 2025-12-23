import 'dart:async';
import 'package:beelingual/exercises/topicExercisesList.dart';
import 'package:beelingual/grammar/gammarList.dart';
import 'package:beelingual/translate.dart';
import 'package:flutter/material.dart';
import 'controller/accountController.dart';
import 'listening/listeningLevel.dart';

class PageHome extends StatefulWidget {
  const PageHome({super.key});

  @override
  _PageHomeState createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
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
      } else {
        print("Access token đã được refresh tự động!");
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await session.logout(context);
            },
          )
        ],
      ),
      body: Column(
        children: [
          const Center(
            child: Text('Chào mừng bạn đến Trang chủ!'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => PageGrammarList()),
              );
            },
            child: const Text('Grammar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => PageTranslate()),
              );
            },
            child: const Text('Translate'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => PageTopicExercisesList()),
              );
            },
            child: const Text('Exercises'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => PageListeningLevel()),
              );
            },
            child: const Text('Listening'),
          ),
        ],
      ),
    );
  }
}
