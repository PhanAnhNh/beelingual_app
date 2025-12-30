// lib/app_UI/pvp/pvp_game_screen.dart
import 'dart:async';
import 'package:beelingual_app/app_UI/Matches_UI/match_result_screen.dart';
import 'package:beelingual_app/connect_api/socket_service.dart';
import 'package:flutter/material.dart';

class PvpGameScreen extends StatefulWidget {
  final dynamic matchData;
  final String myUserId;

  const PvpGameScreen({Key? key, required this.matchData, required this.myUserId}) : super(key: key);

  @override
  State<PvpGameScreen> createState() => _PvpGameScreenState();
}

class _PvpGameScreenState extends State<PvpGameScreen> {
  late List<dynamic> _questions;
  late String _roomId;
  late String _opponentName;

  int _currentQuestionIndex = 0;
  int _myScore = 0;
  int _opponentScore = 0;

  // --- LOGIC MỚI: Timer từng câu ---
  Timer? _questionTimer;
  final int _maxTimePerQuestion = 15; // Cấu hình: 15 giây mỗi câu
  int _timeLeft = 15;

  bool _hasAnswered = false; // Đã trả lời câu này chưa?
  String? _selectedAnswerKey; // Đáp án đã chọn
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _roomId = widget.matchData['roomId'];
    _questions = widget.matchData['questions'];

    var p1 = widget.matchData['player1'];
    var p2 = widget.matchData['player2'];
    if (p1['userId'] == widget.myUserId) {
      _opponentName = p2['username'];
    } else {
      _opponentName = p1['username'];
    }

    _setupSocketListeners();

    // Bắt đầu timer cho câu đầu tiên
    _startQuestionTimer();
  }

  void _setupSocketListeners() {
    SocketService().onOpponentProgress((data) {
      if (mounted) {
        setState(() {
          _opponentScore = data['currentScore'];
        });
      }
    });

    SocketService().onOpponentDisconnected((data) {
      _finishGame(forcedWin: true);
    });
  }

  // Hàm đếm ngược cho từng câu hỏi
  void _startQuestionTimer() {
    _timeLeft = _maxTimePerQuestion;
    _hasAnswered = false;
    _selectedAnswerKey = null;

    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
            // Hết giờ -> Chuyển câu
            timer.cancel();
            _moveToNextQuestion();
          }
        });
      }
    });
  }

  void _onAnswer(String selectedOption) {
    if (_hasAnswered || _isFinished) return; // Chặn nếu đã trả lời

    setState(() {
      _hasAnswered = true;
      _selectedAnswerKey = selectedOption;
    });

    var currentQ = _questions[_currentQuestionIndex];
    bool isCorrect = selectedOption == currentQ['correctAnswer'];

    if (isCorrect) {
      setState(() {
        _myScore += 10;
      });
    }

    // Gửi điểm ngay để đối thủ thấy cập nhật realtime
    SocketService().submitAnswer(_roomId, isCorrect);

    // LƯU Ý QUAN TRỌNG: Không gọi _moveToNextQuestion() ở đây.
    // Chúng ta chỉ đợi Timer tự chạy hết.
  }

  void _moveToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      // Còn câu hỏi
      setState(() {
        _currentQuestionIndex++;
      });
      _startQuestionTimer(); // Reset timer cho câu mới
    } else {
      // Hết câu hỏi -> Kết thúc game
      _finishGame();
    }
  }

  void _finishGame({bool forcedWin = false}) {
    _questionTimer?.cancel();
    _isFinished = true;

    // Gửi tín hiệu kết thúc lên server (để server lưu db)
    // Thời gian dùng có thể tính tổng hoặc bỏ qua tham số này tùy logic server bạn
    SocketService().finishGame(_roomId, _questions.length * _maxTimePerQuestion);
    SocketService().offGameEvents();

    // Chuyển sang màn hình kết quả mới (Thay thế cho màn hình hiện tại)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PvpResultScreen(
          myScore: _myScore,
          opponentScore: _opponentScore,
          opponentName: _opponentName,
          isForcedWin: forcedWin,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    SocketService().offGameEvents();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var question = _questions[_currentQuestionIndex];
    Map<String, dynamic> options = question['options'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Score Board nhỏ
            Column(children: [const Text("Tôi", style: TextStyle(fontSize: 12)), Text("$_myScore", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))]),

            // TIMER CHÍNH GIỮA
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _timeLeft <= 5 ? Colors.red.withOpacity(0.1) : Colors.transparent,
                  shape: BoxShape.circle
              ),
              child: Text(
                  "$_timeLeft",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _timeLeft <= 5 ? Colors.red : Colors.black
                  )
              ),
            ),

            Column(children: [Text(_opponentName, style: const TextStyle(fontSize: 12)), Text("$_opponentScore", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))]),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Thanh tiến trình số câu
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[200],
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 20),

            // Nội dung câu hỏi
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  "Câu ${_currentQuestionIndex + 1}: ${question['content']}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Hiển thị trạng thái chờ nếu đã trả lời xong mà chưa hết giờ
            if (_hasAnswered)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text("Đang chờ hết thời gian...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),

            // Danh sách đáp án
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: options.entries.map((entry) {
                  // Logic màu sắc nút
                  Color bgColor = Colors.white;
                  Color textColor = Colors.black;

                  if (_hasAnswered) {
                    if (entry.key == _selectedAnswerKey) {
                      // Nút mình chọn: Xanh nếu chưa biết đúng sai (hoặc server trả về),
                      // ở đây đơn giản để màu xanh dương để đánh dấu đã chọn.
                      bgColor = Colors.blue.shade100;
                      textColor = Colors.blue;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: bgColor,
                          foregroundColor: textColor,
                          elevation: _hasAnswered ? 0 : 2, // Mất bóng đổ khi đã chọn
                          side: BorderSide(color: _hasAnswered && entry.key == _selectedAnswerKey ? Colors.blue : Colors.grey.shade300),
                        ),
                        // Nếu đã trả lời thì disable nút (null)
                        onPressed: _hasAnswered ? null : () => _onAnswer(entry.key),
                        child: Text("${entry.key}. ${entry.value}", style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}