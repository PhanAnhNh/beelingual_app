import 'package:beelingual_app/connect_api/url.dart';
import 'package:flutter/material.dart';
import 'package:beelingual_app/connect_api/api_connect.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const Color kPrimaryYellow = Color(0xFFFFC107);
const Color kLightYellow   = Color(0xFFFFF8E1);
const Color kDarkText      = Color(0xFF333333);
const Color kSubText       = Color(0xFF777777);

class PvpHistoryScreen extends StatefulWidget {
  const PvpHistoryScreen({super.key});

  @override
  State<PvpHistoryScreen> createState() => _PvpHistoryScreenState();
}

class _PvpHistoryScreenState extends State<PvpHistoryScreen> {
  bool _loading = true;
  List<dynamic> _matchHistory = [];
  String? _errorMessage;

  final SessionManager _session = SessionManager();
  String? myUsername;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadMyUsername();
    await _fetchMatchHistory();
  }

  Future<void> _loadMyUsername() async {
    final profile = await fetchUserProfile(context);
    if (profile != null && mounted) {
      setState(() {
        myUsername = profile['username'];
      });
    }
  }

  // Trong _PvpHistoryScreenState

  Future<void> _fetchMatchHistory() async {
    try {
      final token = await _session.getAccessToken();

      // Gọi API không cần tham số (mặc định page 1)
      final response = await http.get(
        Uri.parse('$urlAPI/api/matches/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        setState(() {
          // --- SỬA Ở ĐÂY ---
          // API trả về { data: [...], pagination: ... }
          // Nên ta phải lấy key ['data']
          _matchHistory = jsonResponse['data'];
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Lỗi tải lịch sử: ${response.statusCode}";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi kết nối: $e";
        _loading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "N/A";
    final d = DateTime.parse(dateString).toLocal();
    return "${d.hour}:${d.minute.toString().padLeft(2, '0')} ${d.day}/${d.month}/${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryYellow,
        centerTitle: true,
        title: const Text(
          "Lịch sử đấu PVP",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : _matchHistory.isEmpty
          ? const Center(child: Text("Bạn chưa đấu trận nào!"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _matchHistory.length,
        itemBuilder: (context, index) {
          final match = _matchHistory[index];

          final p1Name = match['player1']?['username'];
          final p2Name = match['player2']?['username'] ?? 'Bot';

          String leftName;
          String rightName;

          if (myUsername == p1Name) {
            leftName = p1Name;
            rightName = p2Name;
          } else {
            leftName = p2Name;
            rightName = p1Name ?? 'Unknown';
          }

          /// ====== LẤY ĐIỂM ======
          int leftScore = 0;
          int rightScore = 0;

          final results = match['results'] as List<dynamic>? ?? [];

          for (final r in results) {
            if (r['username'] == leftName) {
              leftScore = r['score'] ?? 0;
            }
            if (r['username'] == rightName) {
              rightScore = r['score'] ?? 0;
            }
          }

          /// ====== XÁC ĐỊNH KẾT QUẢ ======
          String resultText;
          Color resultColor;
          IconData resultIcon;

          if (leftScore == rightScore) {
            resultText = "Hòa";
            resultColor = Colors.orange;
            resultIcon = Icons.remove_circle;
          } else {
            final myScore = myUsername == leftName ? leftScore : rightScore;
            final oppScore = myUsername == leftName ? rightScore : leftScore;

            if (myScore > oppScore) {
              resultText = "Thắng";
              resultColor = Colors.green;
              resultIcon = Icons.emoji_events;
            } else {
              resultText = "Thua";
              resultColor = Colors.red;
              resultIcon = Icons.cancel;
            }
          }

          final time = _formatDate(match['endTime']);

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: kLightYellow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFECB3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  /// ===== PLAYER ROW =====
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        child: Icon(Icons.person, color: kPrimaryYellow),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          leftName,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      Column(
                        children: [
                          const Text("VS", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            "$leftScore - $rightScore",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      Expanded(
                        child: Text(
                          rightName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 8),
                      const CircleAvatar(
                        radius: 18,
                        child: Icon(Icons.smart_toy, color: kPrimaryYellow),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// ===== FOOTER =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 14, color: kSubText),
                          const SizedBox(width: 4),
                          Text(time, style: const TextStyle(fontSize: 12)),
                        ],
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: resultColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(resultIcon, size: 14, color: resultColor),
                            const SizedBox(width: 4),
                            Text(
                              resultText,
                              style: TextStyle(
                                color: resultColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
