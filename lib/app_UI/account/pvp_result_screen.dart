import 'package:beelingual_app/connect_api/url.dart';
import 'package:flutter/material.dart';
import 'package:beelingual_app/connect_api/api_connect.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// [Gợi ý] Thêm thư viện intl để format ngày tháng đẹp hơn

const Color kPrimaryYellow = Color(0xFFFFC107); // Amber 500
const Color kLightYellow   = Color(0xFFFFF8E1); // nền card
const Color kDarkText      = Color(0xFF333333);
const Color kSubText       = Color(0xFF777777);


class PvpHistoryScreen extends StatefulWidget {
  const PvpHistoryScreen({super.key});

  @override
  State<PvpHistoryScreen> createState() => _PvpHistoryScreenState();

}

class _PvpHistoryScreenState extends State<PvpHistoryScreen> {
  bool _loading = true;
  List<dynamic> _matchHistory = []; // Danh sách chứa các trận đấu
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


  // Hàm gọi API /api/matches/history
  Future<void> _fetchMatchHistory() async {
    try {
      final session = SessionManager();
      final token = await session.getAccessToken();

      final response = await http.get(
        Uri.parse('$urlAPI/api/matches/history'), // Gọi API lấy danh sách
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _matchHistory = data;
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Lỗi tải lịch sử: ${response.statusCode}";
          _loading = false;
        });
        print("Error: ${response.body}");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi kết nối: $e";
        _loading = false;
      });
    }
  }

  // Hàm helper để format ngày tháng (Ví dụ: 12:30 02/01/2025)
  String _formatDate(String? dateString) {
    if (dateString == null) return "N/A";
    try {
      final DateTime date = DateTime.parse(dateString).toLocal();
      return "${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107), // Amber
        elevation: 2,
        centerTitle: true,
        title: const Text(
          "Lịch sử đấu PVP",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : _matchHistory.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text("Bạn chưa đấu trận nào!"),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _matchHistory.length,
        itemBuilder: (context, index) {
          final match = _matchHistory[index];


          final p1Name = match['player1']?['username'];
          final p2Name = match['player2']?['username'] ?? 'Bot';

          String leftName;
          String rightName;

          if (myUsername != null && p1Name == myUsername) {
            leftName = p1Name;
            rightName = p2Name;
          } else if (myUsername != null && p2Name == myUsername) {
            leftName = p2Name;
            rightName = p1Name ?? 'Unknown';
          } else {
            leftName = p1Name ?? 'Unknown';
            rightName = p2Name;
          }



          // Lấy thời gian kết thúc
          final time = _formatDate(match['endTime']);

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFECB3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  /// ---------- PLAYER ROW ----------
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.person, color: Color(0xFFFFC107)),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          leftName,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF333333),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFC107),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "VS",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Expanded(
                        child: Text(
                          rightName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF333333),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.smart_toy, color: Color(0xFFFFC107)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// ---------- FOOTER ----------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 14, color: Color(0xFF777777)),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF777777),
                            ),
                          ),
                        ],
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle, size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              "Hoàn thành",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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