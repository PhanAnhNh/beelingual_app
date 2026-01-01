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
    _initSocketAndListeners();
    _loadUserProfile();
  }

  void _initSocketAndListeners() {
    SocketService().initSocket();
    SocketService().onMatchFound((data) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PvpGameScreen(
            matchData: data,
            myUserId: _userProfile!['_id'],
          ),
        ),
      );
    });
  }

  Future<void> _loadUserProfile() async {
    final profile = await fetchUserProfile(context);
    if (mounted && profile != null) {
      setState(() => _userProfile = profile['data'] ?? profile);
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

  void _cancelFindMatch() {
    SocketService().disconnect();
    setState(() => _isSearching = false);
    _initSocketAndListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildLevelCard(),
                  const SizedBox(height: 16),
                  _buildQuestionCard(),
                  const Spacer(),
                  _buildFindButton(),
                ],
              ),
            ),
          ),
          if (_isSearching) _buildSearchingOverlay(),
        ],
      ),
    );
  }

  // ================= UI COMPONENT =================

  Widget _buildHeader() {
    return Column(
      children: const [
        Icon(Icons.sports_kabaddi, size: 48, color: Color(0xFFFFC83D)),
        SizedBox(height: 8),
        Text(
          "ĐẤU TRƯỜNG PvP",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          "So tài cùng người chơi khác",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLevelCard() {
    return _goldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🎓 Chọn cấp độ thi đấu",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedLevel,
            items: _levels
                .map((e) =>
                DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged:
            _isSearching ? null : (v) => setState(() => _selectedLevel = v!),
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return _goldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("❓ Số lượng câu hỏi",
              style: TextStyle(fontWeight: FontWeight.bold)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFFC83D),
              thumbColor: const Color(0xFFFFC83D),
              overlayColor: const Color(0x33FFC83D),
            ),
            child: Slider(
              value: _questionCount.toDouble(),
              min: 5,
              max: 20,
              divisions: 3,
              onChanged: _isSearching
                  ? null
                  : (v) => setState(() => _questionCount = v.toInt()),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC83D),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$_questionCount câu",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindButton() {
    return GestureDetector(
      onTap: _userProfile != null ? _startFindMatch : null,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFC83D), Color(0xFFFFA000)],
          ),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flash_on, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "TÌM TRẬN ĐẤU",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingOverlay() {
    return Container(
      color: Colors.black45,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            const Text("Đang tìm đối thủ...",
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _cancelFindMatch,
              child: const Text("Hủy tìm",
                  style: TextStyle(color: Colors.redAccent)),
            )
          ],
        ),
      ),
    );
  }

  Widget _goldCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1C1),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
