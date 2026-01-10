// lib/app_UI/pvp/pvp_game_screen.dart
import 'dart:async';
import 'package:beelingual_app/app_UI/Matches_UI/match_result_screen.dart';
import 'package:beelingual_app/app_UI/home_UI/home_page.dart';
import 'package:beelingual_app/connect_api/socket_service.dart';
import 'package:beelingual_app/model/model_exercise.dart';
import 'package:flutter/material.dart';

class PvpGameScreen extends StatefulWidget {
  final dynamic matchData;
  final String myUserId;

  const PvpGameScreen({Key? key, required this.matchData, required this.myUserId})
      : super(key: key);

  @override
  State<PvpGameScreen> createState() => _PvpGameScreenState();
}

class _PvpGameScreenState extends State<PvpGameScreen> with TickerProviderStateMixin {
  late List<Exercises> _questions;
  late String _roomId;
  late String _opponentName;

  // Điểm số và trạng thái
  int _currentQuestionIndex = 0;
  int _myScore = 0;
  int _opponentScore = 0;

  // Logic Timer
  Timer? _questionTimer;
  int _maxTimePerQuestion = 15;
  int _timeLeft = 15;

  // Logic Trả lời
  bool _hasAnswered = false;
  String? _selectedAnswerKey;
  bool _isFinished = false;

  // Biến kiểm soát Dialog kết quả vòng
  bool _isShowingRoundResult = false;

  // Colors Palette
  final Color _primaryColor = const Color(0xFF6A5AE0);
  final Color _secondaryColor = const Color(0xFF9087E5);
  final Color _bgColor = const Color(0xFFF0F3F9);

  @override
  void initState() {
    super.initState();
    _roomId = widget.matchData['roomId'] ?? 'unknown_room';

    // Parse Questions
    List<dynamic> rawQuestions = widget.matchData['questions'] ?? [];
    try {
      _questions = rawQuestions.map((q) => Exercises.fromJson(q)).toList();
    } catch (e) {
      _questions = [];
    }

    _maxTimePerQuestion = widget.matchData['timePerQuestion'] ?? 15;
    _timeLeft = _maxTimePerQuestion;

    // Parse User Names
    var p1 = widget.matchData['player1'];
    var p2 = widget.matchData['player2'];
    if (p1 != null && p2 != null) {
      if (p2['username'] == 'Mr. Robot 🤖' || p2['userId'] == 'BOT_ID') {
        _opponentName = "Mr. Robot 🤖";
      } else {
        _opponentName = (p1['userId'] == widget.myUserId)
            ? (p2['username'] ?? "Đối thủ")
            : (p1['username'] ?? "Đối thủ");
      }
    } else {
      _opponentName = "Đối thủ";
    }

    _setupSocketListeners();

    if (_questions.isNotEmpty) {
      _startQuestionTimer();
    }
  }

  void _setupSocketListeners() {
    final socket = SocketService();

    // 1. Nhận kết quả vòng đấu (Show Popup)
    socket.onRoundResult((data) {
      if (!mounted || _isFinished) return;
      print("🏆 Round Result: $data");

      // Dừng timer đếm ngược câu hỏi
      _questionTimer?.cancel();

      // Phân tích dữ liệu điểm
      String correctAnswer = data['correctAnswer'];
      List<dynamic> players = data['players'];

      int myRoundPoints = 0;
      int oppRoundPoints = 0;
      bool amICorrect = false;

      // Cập nhật điểm tổng ngay lập tức
      for (var p in players) {
        String pId = p['userId'].toString();
        int totalScore = (p['totalScore'] is int) ? p['totalScore'] : int.parse(p['totalScore'].toString());
        int addedScore = (p['addedScore'] is int) ? p['addedScore'] : int.parse(p['addedScore'].toString());

        if (pId == widget.myUserId) {
          _myScore = totalScore;
          myRoundPoints = addedScore;
          amICorrect = p['isCorrect'];
        } else {
          _opponentScore = totalScore;
          oppRoundPoints = addedScore;
        }
      }

      setState(() {}); // Rebuild để cập nhật điểm trên Header

      // Hiển thị Popup kết quả (đợi 3s trước khi server gửi next_question)
      _showRoundResultDialog(correctAnswer, myRoundPoints, oppRoundPoints, amICorrect);
    });

    // 2. Chuyển câu hỏi mới
    socket.onNextQuestion((data) {
      if (!mounted) return;

      // Nếu Popup đang hiện thì tắt nó đi
      if (_isShowingRoundResult && Navigator.canPop(context)) {
        Navigator.pop(context);
        _isShowingRoundResult = false;
      }

      final question = Exercises.fromJson(data['content']);

      setState(() {
        _currentQuestionIndex = (data['questionIndex'] ?? 1) - 1;

        // Cập nhật/Thêm câu hỏi vào list (đề phòng list ban đầu thiếu)
        if (_questions.length <= _currentQuestionIndex) {
          _questions.add(question);
        } else {
          _questions[_currentQuestionIndex] = question;
        }

        // Reset
        _maxTimePerQuestion = data['timeLimit'] ?? 10;
        _timeLeft = _maxTimePerQuestion;
        _hasAnswered = false;
        _selectedAnswerKey = null;
      });

      _startQuestionTimer();
    });

    // 3. Đối thủ trả lời xong (cập nhật tiến độ realtime nếu muốn)
    socket.onOpponentProgress((data) {
      if (!mounted) return;
      if (data['opponentId'].toString() != widget.myUserId) {
        // Có thể hiển thị animation đối thủ đã xong, nhưng chưa cộng điểm thật
        // Điểm thật sẽ cập nhật ở round_result
      }
    });

    // 4. Kết thúc game
    socket.onGameFinished((data) {
      if (!mounted) return;
      // Đảm bảo đóng popup nếu còn
      if (_isShowingRoundResult && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _finishGame();
    });

    // 5. Đối thủ thoát
    socket.onOpponentDisconnected((data) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      _finishGame(forcedWin: true);
    });
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          timer.cancel();
          // Hết giờ -> Không làm gì cả, chờ Server gửi round_result
        }
      });
    });
  }

  // lib/app_UI/pvp/pvp_game_screen.dart

  void _onAnswer(int optionIndex) {
    if (_hasAnswered || _isFinished) return;

    Exercises currentQuestion = _questions[_currentQuestionIndex];
    final answerText = currentQuestion.options[optionIndex].text;
    // --------------------

    setState(() {
      _hasAnswered = true;
      _selectedAnswerKey = String.fromCharCode(65 + optionIndex); // Vẫn giữ key A/B/C để highlight UI
    });

    // Gửi text lên server
    SocketService().submitAnswer(
      _roomId,
      answerText, // Gửi "Màu đỏ"
    );
  }

  // --- HIỂN THỊ POPUP KẾT QUẢ VÒNG ---
  void _showRoundResultDialog(String correctAnswer, int myPts, int oppPts, bool amICorrect) {
    _isShowingRoundResult = true;
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho bấm ra ngoài
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // Chặn nút back
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: amICorrect ? Colors.green : Colors.redAccent,
                          width: 4
                      )
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tiêu đề
                      Text(
                        amICorrect ? "CHÍNH XÁC! 🎉" : "SAI RỒI! 😢",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: amICorrect ? Colors.green : Colors.red
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Đáp án đúng
                      Text("Đáp án đúng:", style: TextStyle(color: Colors.grey[600])),
                      Text(
                        correctAnswer,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87
                        ),
                      ),
                      const Divider(height: 30),

                      // Điểm số nhận được
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRoundScoreItem("Tôi", myPts, true),
                          Container(width: 1, height: 40, color: Colors.grey[300]),
                          _buildRoundScoreItem(_opponentName, oppPts, false),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(), // Loading bar chờ câu tiếp
                      const SizedBox(height: 5),
                      const Text("Câu tiếp theo trong 3s...", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => _isShowingRoundResult = false);
  }

  Widget _buildRoundScoreItem(String name, int points, bool isMe) {
    return Column(
      children: [
        Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? _primaryColor : Colors.black54)),
        const SizedBox(height: 5),
        Text(
          "+$points",
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: points > 0 ? Colors.amber : Colors.grey
          ),
        )
      ],
    );
  }

  void _finishGame({bool forcedWin = false}) {
    if (_isFinished) return;
    _isFinished = true;
    _questionTimer?.cancel();
    SocketService().offGameEvents();

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

  void _handleSurrender() {
    _questionTimer?.cancel();
    SocketService().leaveRoom(_roomId);
    SocketService().offGameEvents();
    Navigator.pop(context); // Thoát màn hình
  }

  Future<bool> _onWillPop() async {
    // (Giữ nguyên logic cảnh báo thoát game)
    return await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Cảnh báo"),
          content: const Text("Thoát bây giờ bạn sẽ bị xử thua."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Ở lại")),
            TextButton(onPressed: () { _handleSurrender(); Navigator.pop(ctx, true); }, child: const Text("Thoát", style: TextStyle(color: Colors.red))),
          ],
        )
    ) ?? false;
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    SocketService().offGameEvents();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Loading ban đầu
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return Scaffold(backgroundColor: _bgColor, body: const Center(child: CircularProgressIndicator()));
    }

    Exercises question = _questions[_currentQuestionIndex];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Header (Updated Score)
              _buildHeader(),

              // 2. Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / _questions.length,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    color: _primaryColor,
                  ),
                ),
              ),

              // 3. Question & Options
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Card Câu hỏi
                      Expanded(
                        flex: 4,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Câu hỏi ${_currentQuestionIndex + 1}", style: TextStyle(color: _secondaryColor, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              Text(question.questionText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),

                      // Trạng thái chờ
                      if (_hasAnswered)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor)),
                              const SizedBox(width: 8),
                              const Text("Đang chờ đối thủ...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        )
                      else
                        const SizedBox(height: 32),

                      // Đáp án
                      Expanded(
                        flex: 6,
                        child: SingleChildScrollView(
                          child: Column(
                            children: question.options.asMap().entries.map((entry) {
                              return _buildOptionButton(entry.key, entry.value);
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPlayerProfile("Tôi", _myScore, isMe: true), // Điểm cập nhật realtime từ round_result

          // Timer
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60, height: 60,
                child: CircularProgressIndicator(
                  value: _timeLeft / _maxTimePerQuestion,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey[200],
                  color: _timeLeft <= 5 ? Colors.red : _primaryColor,
                ),
              ),
              Text("$_timeLeft", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _timeLeft <= 5 ? Colors.red : _primaryColor)),
            ],
          ),

          _buildPlayerProfile(_opponentName, _opponentScore, isMe: false),
        ],
      ),
    );
  }

  Widget _buildPlayerProfile(String name, int score, {required bool isMe}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: isMe ? _secondaryColor.withOpacity(0.2) : Colors.red.withOpacity(0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "?",
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold,
              color: isMe ? _primaryColor : Colors.redAccent,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(name.length > 8 ? "${name.substring(0, 7)}..." : name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: isMe ? _primaryColor : Colors.redAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "$score", // Giá trị này sẽ đổi khi nhận round_result
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        )
      ],
    );
  }

  Widget _buildOptionButton(int index, Option opt) {
    String label = String.fromCharCode(65 + index);
    bool isSelected = _hasAnswered && label == _selectedAnswerKey;

    // Màu sắc chỉ mang tính chất highlight lựa chọn của mình (chưa biết đúng sai)
    Color bgColor = isSelected ? _primaryColor.withOpacity(0.1) : Colors.white;
    Color borderColor = isSelected ? _primaryColor : Colors.grey.shade200;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _hasAnswered ? null : () => _onAnswer(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey[600])),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(opt.text, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}