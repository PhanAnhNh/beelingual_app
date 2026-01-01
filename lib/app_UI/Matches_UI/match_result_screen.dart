// lib/app_UI/pvp/pvp_result_screen.dart
import 'package:beelingual_app/app_UI/Matches_UI/find_match_screen.dart';
import 'package:beelingual_app/app_UI/home_UI/bottom_navigation.dart';
import 'package:flutter/material.dart';

class PvpResultScreen extends StatelessWidget {
  final int myScore;
  final int opponentScore;
  final String opponentName;
  final bool isForcedWin;

  const PvpResultScreen({
    Key? key,
    required this.myScore,
    required this.opponentScore,
    required this.opponentName,
    this.isForcedWin = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ===== XÁC ĐỊNH KẾT QUẢ =====
    late String title;
    late String subTitle;
    late IconData icon;
    late Color mainColor;

    if (isForcedWin || myScore > opponentScore) {
      title = "YOU WIN!";
      subTitle = "Great job! You're improving your English 💪";
      icon = Icons.emoji_events_rounded;
      mainColor = const Color(0xFFFFC83D); // vàng
    } else if (myScore < opponentScore) {
      title = "TRY AGAIN!";
      subTitle = "Every mistake helps you learn better 📘";
      icon = Icons.sentiment_dissatisfied_rounded;
      mainColor = const Color(0xFFFFB4A2); // đỏ dịu
    } else {
      title = "IT’S A DRAW!";
      subTitle = "Well matched! Keep practicing 🚀";
      icon = Icons.handshake_rounded;
      mainColor = const Color(0xFFFFC83D);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),

              // ===== ICON + TITLE =====
              Icon(icon, size: 110, color: mainColor),
              const SizedBox(height: 16),

              Text(
                title,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.brown.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subTitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),

              const SizedBox(height: 40),

              // ===== CARD TỶ SỐ =====
              _scoreCard(),

              const SizedBox(height: 20),

              // ===== XP =====
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "⭐ 10 XP | 3 New Words",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              const Spacer(),

              // ===== BUTTON CHƠI TIẾP =====
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text("CHƠI TIẾP"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC83D),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                FindMatchScreen()),
                    );
                  },

                ),
              ),

              const SizedBox(height: 12),

              // ===== BUTTON VỀ TRANG CHỦ =====
              TextButton.icon(
                icon: const Icon(Icons.home_outlined),
                label: const Text("VỀ TRANG CHỦ"),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const home_navigation()), // <--- Thay 'HomeScreen' bằng tên Class màn hình chính của bạn
                        (route) => false, // Điều kiện false nghĩa là xóa hết stack cũ
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== CARD SO SÁNH =====
  Widget _scoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _playerColumn("Bạn", myScore, Colors.blue),
          const Text(
            "VS",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          _playerColumn(opponentName, opponentScore, Colors.orange),
        ],
      ),
    );
  }

  Widget _playerColumn(String name, int score, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.person, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          "$score",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
