import 'package:beelingual/model/model_Topic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beelingual/component/progressProvider.dart';
import 'package:beelingual/app_UI/vocabulary_UI/list_Vocab.dart';

class LevelPage extends StatefulWidget {
  final String topicId;
  final String topicName;
  final VoidCallback? onProgressUpdated;
  final Topic topic;

  const LevelPage({
    super.key,
    required this.topicId,
    required this.topicName,
    this.onProgressUpdated,
    required this.topic,
  });

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage> {
  /// 📊 Level codes
  final List<String> levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  /// 🏷️ Level names tương ứng
  final Map<String, String> levelNames = {
    'A1': 'Beginner',
    'A2': 'Elementary',
    'B1': 'Intermediate',
    'B2': 'Upper-Intermediate',
    'C1': 'Advanced',
    'C2': 'Proficient',
  };

  /// 🎨 Gradient cho từng card
  final List<List<Color>> cardGradients = [
    [Color(0xFFFFC371), Color(0xFFFFA751)],
    [Color(0xFFB6F492), Color(0xFF338B93)],
    [Color(0xFFD4BFFF), Color(0xFF9B6DFF)],
    [Color(0xFFA1FFCE), Color(0xFF3EB489)],
    [Color(0xFFFFD194), Color(0xFFFF8A65)],
    [Color(0xFF81D4FA), Color(0xFF4FC3F7)],
  ];

  @override
  Widget build(BuildContext context) {
    final progress = Provider.of<UserProgressProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFE474),
        title: Text(
          widget.topicName,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF5D4037),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF5D4037)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildProgress(progress),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: levels.length,
              itemBuilder: (context, index) {
                return _levelCard(
                  index: index,
                  level: levels[index],
                  gradient: cardGradients[index % cardGradients.length],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 Progress Bar
  Widget _buildProgress(UserProgressProvider progress) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: widget.topic.progress / 100,
              minHeight: 18,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF81C784)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress.currentLevel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('${widget.topic.progress}%'),
            ],
          ),
        ],
      ),
    );
  }

  /// 🎴 Level Card
  Widget _levelCard({
    required int index,
    required String level,
    required List<Color> gradient,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VocabularyCardScreen(
              topicId: widget.topicId,
              topicName: widget.topicName,
              level: level,
              onProgressUpdated: widget.onProgressUpdated,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: gradient),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            /// 🔢 Index
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),

            const SizedBox(width: 16),

            /// 📘 Level info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level $level',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    levelNames[level] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
