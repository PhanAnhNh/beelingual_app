// lib/app_UI/pvp/find_match_screen.dart
import 'package:beelingual_app/connect_api/api_connect.dart';
import 'package:beelingual_app/connect_api/socket_service.dart';
import 'package:flutter/material.dart';
import 'pvp_game_screen.dart';

class FindMatchScreen extends StatefulWidget {
  const FindMatchScreen({Key? key}) : super(key: key);

  @override
  State<FindMatchScreen> createState() => _FindMatchScreenState();
}

class _FindMatchScreenState extends State<FindMatchScreen> {
  String _selectedLevel = 'A1';
  int _questionCount = 5;
  bool _isSearching = false;
  Map<String, dynamic>? _userProfile;

  final List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'C1'];

  @override
  void initState() {
    super.initState();
    // 1. Khởi tạo socket và lắng nghe
    _initSocketAndListeners();

    // 2. Lấy thông tin User
    _loadUserProfile();
  }

  // Tách hàm này ra để có thể gọi lại khi bấm "Hủy" rồi tìm lại
  void _initSocketAndListeners() {
    SocketService().initSocket();

    // Lắng nghe sự kiện tìm thấy trận
    SocketService().onMatchFound((data) {
      if (!mounted) return;
      setState(() => _isSearching = false);

      // Chuyển sang màn chơi game
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PvpGameScreen(matchData: data, myUserId: _userProfile!['_id']),
        ),
      );
    });
  }

  Future<void> _loadUserProfile() async {
    // ... (Giữ nguyên code cũ của bạn) ...
    print("🔄 Đang lấy user profile...");
    final profile = await fetchUserProfile(context);
    print("📥 Dữ liệu API trả về: $profile");

    if (mounted && profile != null) {
      setState(() {
        _userProfile = profile['data'] ?? profile;
      });
    }
  }

  void _startFindMatch() {
    if (_userProfile == null) return;

    setState(() => _isSearching = true);

    SocketService().joinQueue(
      userId: _userProfile!['_id'],
      username: _userProfile!['username'] ?? 'Unknown',
      avatarUrl: _userProfile!['avatarUrl'] ?? '',
      level: _selectedLevel,
      questionCount: _questionCount,
    );
  }

  // --- HÀM MỚI: HỦY TÌM TRẬN ---
  void _cancelFindMatch() {
    // 1. Ngắt kết nối socket để Server biết user thoát hàng chờ
    SocketService().disconnect();

    // 2. Cập nhật UI về trạng thái chưa tìm
    setState(() {
      _isSearching = false;
    });

    // 3. Kết nối lại Socket ngay lập tức để sẵn sàng cho lần tìm sau
    // (Nếu không có bước này, bấm tìm lại sẽ không gửi được tin hiệu vì socket đang đóng)
    _initSocketAndListeners();
  }

  @override
  void dispose() {
    if (_isSearching) {
      SocketService().disconnect();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đấu Trường PvP")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Chọn cấp độ thi đấu:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedLevel,
              isExpanded: true,
              items: _levels.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              // Khi đang tìm trận thì khóa chọn level
              onChanged: _isSearching ? null : (val) => setState(() => _selectedLevel = val!),
            ),

            const SizedBox(height: 20),

            const Text("Số lượng câu hỏi:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Slider(
              value: _questionCount.toDouble(),
              min: 5,
              max: 20,
              divisions: 3,
              label: _questionCount.toString(),
              onChanged: _isSearching ? null : (val) => setState(() => _questionCount = val.toInt()),
            ),
            Text("$_questionCount câu", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),

            const Spacer(),

            // --- PHẦN UI THAY ĐỔI ---
            if (_isSearching)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text("Đang tìm đối thủ...", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 20),

                  // Nút Hủy Mới Thêm
                  OutlinedButton.icon(
                    onPressed: _cancelFindMatch,
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text("Hủy tìm kiếm", style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: _userProfile != null ? _startFindMatch : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.blueAccent,
                ),
                child: const Text("TÌM TRẬN ĐẤU", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}