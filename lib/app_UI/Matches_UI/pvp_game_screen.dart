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

  int _currentQuestionIndex = 0;
  int _myScore = 0;
  int _opponentScore = 0;

  // --- LOGIC ---
  Timer? _questionTimer;
  final int _maxTimePerQuestion = 15;
  int _timeLeft = 15;

  bool _hasAnswered = false;
  String? _selectedAnswerKey;
  bool _isFinished = false;

  // Colors Palette
  final Color _primaryColor = const Color(0xFF6A5AE0); // Tím đậm
  final Color _secondaryColor = const Color(0xFF9087E5); // Tím nhạt
  final Color _accentColor = const Color(0xFFFFD056); // Vàng cam (cho điểm số/timer)
  final Color _bgColor = const Color(0xFFF0F3F9); // Xám xanh nhạt

  @override
  void initState() {
    super.initState();
    _roomId = widget.matchData['roomId'];

    List<dynamic> rawQuestions = widget.matchData['questions'];
    _questions = rawQuestions.map((q) => Exercises.fromJson(q)).toList();

    var p1 = widget.matchData['player1'];
    var p2 = widget.matchData['player2'];
    if (p1['userId'] == widget.myUserId) {
      _opponentName = p2['username'];
    } else {
      _opponentName = p1['username'];
    }

    _setupSocketListeners();
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
            timer.cancel();
            _moveToNextQuestion();
          }
        });
      }
    });
  }

  void _onAnswer(String selectedOptionText) {
    if (_hasAnswered || _isFinished) return;

    setState(() {
      _hasAnswered = true;
      _selectedAnswerKey = selectedOptionText;
    });

    var currentQ = _questions[_currentQuestionIndex];
    bool isCorrect = selectedOptionText == currentQ.correctAnswer;

    if (isCorrect) {
      setState(() {
        _myScore += 10;
      });
    }

    SocketService().submitAnswer(_roomId, isCorrect);
  }

  void _moveToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _startQuestionTimer();
    } else {
      _finishGame();
    }
  }

  void _finishGame({bool forcedWin = false}) {
    _questionTimer?.cancel();
    _isFinished = true;
    SocketService().finishGame(_roomId, _questions.length * _maxTimePerQuestion);
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false, // Xóa hết lịch sử cũ để không bấm Back quay lại game được
    );
  }

  Future<bool> _onWillPop() async {
    bool? shouldLeave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cảnh báo", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Thoát bây giờ bạn sẽ bị xử thua. Bạn chắc chắn chứ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Ở lại", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Thoát", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      _handleSurrender();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    SocketService().offGameEvents();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Exercises question = _questions[_currentQuestionIndex];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Header Area (Custom)
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

              // 3. Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Question Card
                      Expanded(
                        flex: 4,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Câu hỏi ${_currentQuestionIndex + 1}",
                                style: TextStyle(
                                  color: _secondaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                question.questionText,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Waiting Indicator
                      if (_hasAnswered)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor)
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Đợi đối thủ...",
                                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(height: 32),

                      // Options List
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
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Player (Me)
          _buildPlayerProfile("Tôi", _myScore, isMe: true),

          // Timer (Center)
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: _timeLeft / _maxTimePerQuestion,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey[200],
                  color: _timeLeft <= 5 ? Colors.red : _primaryColor,
                ),
              ),
              Text(
                "$_timeLeft",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _timeLeft <= 5 ? Colors.red : _primaryColor,
                ),
              ),
            ],
          ),

          // Opponent
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isMe ? _primaryColor : Colors.redAccent,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name.length > 8 ? "${name.substring(0, 7)}..." : name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: isMe ? _primaryColor : Colors.redAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "$score",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildOptionButton(int index, Option opt) {
    String label = String.fromCharCode(65 + index); // A, B, C, D
    bool isSelected = _hasAnswered && opt.text == _selectedAnswerKey;

    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Color textColor = Colors.black87;

    if (isSelected) {
      bgColor = _primaryColor.withOpacity(0.1);
      borderColor = _primaryColor;
      textColor = _primaryColor;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _hasAnswered ? null : () => _onAnswer(opt.text),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: _hasAnswered ? [] : [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              // Label Circle (A, B, C, D)
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Answer Text
              Expanded(
                child: Text(
                  opt.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}