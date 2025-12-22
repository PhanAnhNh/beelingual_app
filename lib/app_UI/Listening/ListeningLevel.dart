import 'dart:ffi';

import 'package:beelingual_app/app_UI/Listening/listeningEx.dart';
import 'package:beelingual_app/model/molel_level.dart';
import 'package:flutter/material.dart';

class PageListeningLevel extends StatefulWidget {
  const PageListeningLevel({super.key});

  @override
  State<PageListeningLevel> createState() => _PageListeningLevelState();
}

class _PageListeningLevelState extends State<PageListeningLevel> {
  String skill = "listening";
  final List<Level> levels = [
    Level(levelID: 'A1', levelName: 'Beginner'),
    Level(levelID: 'A2', levelName: 'Elementary'),
    Level(levelID: 'B1', levelName: 'Intermediate'),
    Level(levelID: 'B2', levelName: 'Upper Intermediate'),
    Level(levelID: 'C1', levelName: 'Advanced'),
    Level(levelID: 'C2', levelName: 'Proficiency'),
  ];

  Color _getLevelColor(String levelID) {
    switch (levelID) {
      case 'A1':
        return Colors.green[300]!;
      case 'A2':
        return Colors.lightGreen[400]!;
      case 'B1':
        return Colors.blue[300]!;
      case 'B2':
        return Colors.blue[600]!;
      case 'C1':
        return Colors.orange[400]!;
      case 'C2':
        return Colors.red[400]!;
      default:
        return Colors.grey;
    }
  }

  void _navigateToLevel(Level level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PageListeningExercise(level: level.levelID, skill: skill),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listening'),
        backgroundColor: Color(0xFFFFF176),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF9C4),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: levels.length,
                  itemBuilder: (context, index) {
                    final level = levels[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _navigateToLevel(level),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  _getLevelColor(level.levelID),
                                  _getLevelColor(level.levelID).withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      level.levelID,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: _getLevelColor(level.levelID),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        level.levelName,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'CEFR ${level.levelID}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}