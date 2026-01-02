// lib/app_UI/pvp/find_match_screen.dart
import 'dart:async';
import 'dart:ui'; // Cần import để dùng BackdropFilter
import 'package:beelingual_app/connect_api/api_connect.dart';
import 'package:beelingual_app/connect_api/socket_service.dart';
import 'package:flutter/material.dart';
import 'pvp_game_screen.dart';

class FindMatchScreen extends StatefulWidget {
  const FindMatchScreen({Key? key}) : super(key: key);

  @override
  State<FindMatchScreen> createState() => _FindMatchScreenState();
}

class _FindMatchScreenState extends State<FindMatchScreen> with SingleTickerProviderStateMixin {
  String _selectedLevel = 'A1';
  int _questionCount = 5;
  bool _isSearching = false;
  Map<String, dynamic>? _userProfile;
  Timer? _botRequestTimer;

  final List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'C1'];

  // Animation controller cho hiệu ứng "thở" (pulse) khi tìm trận
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initSocketAndListeners();
    _loadUserProfile();

    // Setup Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _botRequestTimer?.cancel(); // Hủy timer nếu thoát màn hình
    super.dispose();
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

    // 1. Gửi yêu cầu tìm trận bình thường
    SocketService().joinQueue(
      userId: _userProfile!['_id'],
      username: _userProfile!['username'] ?? 'Unknown',
      avatarUrl: _userProfile!['avatarUrl'] ?? '',
      level: _selectedLevel,
      questionCount: _questionCount,
    );

    // 2. --- SỬA Ở ĐÂY: Đếm ngược 10-15 giây để gọi Bot ---
    _botRequestTimer?.cancel();
    _botRequestTimer = Timer(const Duration(seconds: 12), () {
      // Nếu sau 12 giây vẫn đang tìm (_isSearching == true)
      if (_isSearching && mounted) {
        print("Đợi lâu quá, chuyển sang đấu với Bot...");
        // Gọi hàm mới trong SocketService (bạn cần thêm hàm này vào file socket)
        SocketService().requestBotMatch();
      }
    });
  }

  void _cancelFindMatch() {
    SocketService().disconnect();
    _botRequestTimer?.cancel(); // Hủy timer bot
    setState(() => _isSearching = false);
    _initSocketAndListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      extendBodyBehindAppBar: true,
      appBar: _isSearching
          ? null
          : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),

        title: const Text(
          "PvP Arena",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // MAIN CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildLevelCard(),
                  const SizedBox(height: 16),
                  _buildQuestionCard(),
                  const Spacer(),
                  _buildFindButton(),
                ],
              ),
            ),
          ),

          // SEARCHING OVERLAY
          if (_isSearching) _buildSearchingOverlay(),
        ],
      ),
    );
  }

  // ================= UI COMPONENT =================

  Widget _buildSearchingOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          // 1. Lớp nền mờ tối
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.85),
            ),
          ),

          // 2. Nội dung chính giữa
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar Pulse Animation
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFC83D), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFC83D).withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    // --- SỬA Ở ĐÂY: DÙNG ASSET IMAGE ---
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      // Thay đường dẫn này bằng đường dẫn file ảnh thật của bạn
                      backgroundImage: AssetImage('assets/Images/logoBee.png'),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Text: Searching
                const Text(
                  "Đang tìm đối thủ...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),

                // Info: Level & Question
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Cấp độ: $_selectedLevel  •  $_questionCount câu hỏi",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // 3. Nút Hủy to ở dưới cùng
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _cancelFindMatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close_rounded, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "HỦY TÌM KIẾM",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: const [
        Icon(Icons.emoji_events_rounded, size: 60, color: Color(0xFFFFC83D)),
        SizedBox(height: 10),
        Text(
          "ĐẤU TRƯỜNG PvP",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Text(
          "Thách đấu thời gian thực",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildLevelCard() {
    return _goldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.school_rounded, color: Color(0xFFB58900)),
              SizedBox(width: 8),
              Text("Cấp độ thi đấu",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedLevel,
            items: _levels
                .map((e) => DropdownMenuItem(value: e, child: Text("Level $e")))
                .toList(),
            onChanged:
            _isSearching ? null : (v) => setState(() => _selectedLevel = v!),
            decoration: _inputDecoration(),
            icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFFB58900)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.quiz_rounded, color: Color(0xFFB58900)),
                  SizedBox(width: 8),
                  Text("Số lượng câu hỏi",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1C1),
                  border: Border.all(color: const Color(0xFFB58900)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$_questionCount câu",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB58900)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFFC83D),
              inactiveTrackColor: Colors.grey[300],
              thumbColor: const Color(0xFFFFC83D),
              overlayColor: const Color(0x33FFC83D),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _questionCount.toDouble(),
              min: 5,
              max: 20,
              divisions: 3,
              label: "$_questionCount",
              onChanged: _isSearching
                  ? null
                  : (v) => setState(() => _questionCount = v.toInt()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("5", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("10", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("15", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("20", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFindButton() {
    return GestureDetector(
      onTap: _userProfile != null ? _startFindMatch : null,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC83D).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
          gradient: const LinearGradient(
            colors: [Color(0xFFFFC83D), Color(0xFFFFA000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                "TÌM ĐỐI THỦ NGAY",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goldCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFF1C1), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFFFFBF0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}