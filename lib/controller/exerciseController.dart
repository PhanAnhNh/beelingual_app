import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../app_UI/Exe_UI/SummaryExeList.dart';
import '../component/messDialog.dart';
import '../connect_api/url.dart';
import '../connect_api/tts_service.dart';
import '../model/model_exercise.dart';

class ExerciseController {
  List<Exercises> exercises = [];
  Map<String,String> submittedAnswers = {};
  Map<String, String> userAnswers = {};
  int currentIndex = 0;

  final TTSService _ttsService = TTSService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  Future<void> fetchExercisesByTopicId(String topicId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('Token không tồn tại. Vui lòng đăng nhập.');
    }

    final url = Uri.parse(
      '$urlAPI/api/exercises?topicId=$topicId&limit=10&random=true',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Không lấy được dữ liệu (${response.statusCode})');
    }

    final decoded = json.decode(response.body);
    final List<dynamic> dataList = decoded['data'];

    exercises = dataList
        .map((item) => Exercises.fromJson(item))
        .toList();

    currentIndex = 0;
    userAnswers.clear();
    
    await _initializeTTSSession();
  }
  
  Future<void> _initializeTTSSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'guest';
    await _ttsService.initSession(userId);
    
    final listeningIds = exercises
        .where((ex) => ex.skill == 'listening')
        .map((ex) => ex.id)
        .toList();

    if (listeningIds.isNotEmpty) {
      print('⏳ Waiting for ${listeningIds.length} audio files to download...');
      await _ttsService.prefetchAll(listeningIds);
      print('✅ All audio files ready!');
    }
  }


  Future<void> fetchExercisesByLevelAndSkill({
    required String level,
    required String skill,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('Token không tồn tại. Vui lòng đăng nhập.');
    }

    final url = Uri.parse('$urlAPI/api/exercises?level=$level&skill=$skill&topicId=null&limit=10&random=true');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Không lấy được dữ liệu (${response.statusCode})');
    }

    final decoded = json.decode(response.body);
    final List<dynamic> dataList = decoded['data'];

    exercises = dataList
        .map((item) => Exercises.fromJson(item))
        .toList();

    currentIndex = 0;
    userAnswers.clear();
    await _initializeTTSSession();
  }


  Future<void> answerQuestion({
    required BuildContext context,
    required String userAnswer,
  }) async {
    final ex = exercises[currentIndex];
    if (userAnswers.containsKey(ex.id)) return;
    await stopSpeaking();
    userAnswers[ex.id] = userAnswer;
    submittedAnswers[ex.id] = userAnswer;
    final bool isCorrect = userAnswer.trim().toLowerCase() == ex.correctAnswer.trim().toLowerCase();

    if (isCorrect) {
      await showSuccessDialog(context, "Thông báo","Bạn đã trả lời đúng!");
    } else {
      await showErrorDialog(context, "Thông báo","Sai rồi!");
    }

    goToNextQuestion(context);
  }


  void goToNextQuestion(BuildContext context) async {
    if (currentIndex < exercises.length - 1) {
      currentIndex++;
      return;
    }

    await _ttsService.cleanupSession();
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          exercises: exercises,
          userAnswers: userAnswers,
        ),
      ),
    );
  }

  bool isAnswered() {
    final ex = exercises[currentIndex];
    return userAnswers.containsKey(ex.id);
  }

  VoidCallback? onAudioStateChange;


  Future<void> speakLisExercises({
    required String exerciseId,
    required String audioUrl,
    required String level,
  }) async {
    if (audioUrl.isEmpty) return;

    if (isPlaying) {
      await _audioPlayer.stop();
      isPlaying = false;
      onAudioStateChange?.call();
      return;
    }

    try {
      isPlaying = true;
      onAudioStateChange?.call();

      final source = await _ttsService.getAudioSource(exerciseId);

      if (source is DeviceFileSource) {
        await _audioPlayer.play(source);
      } else if (source is UrlSource) {
        await _audioPlayer.play(source);
      }

      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((_) {
        isPlaying = false;
        onAudioStateChange?.call();
      });
      
    } catch (e) {
      print('❌ Error playing Gemini audio: $e');
      isPlaying = false;
      onAudioStateChange?.call();
    }
  }

  Future<void> speakExercises(String exerciseId, String audioText) async {
    if (audioText.isEmpty) return;

    if (isPlaying) {
      await _audioPlayer.stop();
      isPlaying = false;
      onAudioStateChange?.call();
      return;
    }

    try {
      isPlaying = true;
      onAudioStateChange?.call();

      final source = await _ttsService.getAudioSource(exerciseId);

      if (source is DeviceFileSource) {
        await _audioPlayer.play(source);
      } else if (source is UrlSource) {
        await _audioPlayer.play(source);
      }

      _audioPlayer.onPlayerComplete.listen((_) {
        isPlaying = false;
        onAudioStateChange?.call();
      });
      
    } catch (e) {
      print('❌ Error playing audio: $e');
      isPlaying = false;
      onAudioStateChange?.call();
    }
  }

  Future<void> stopSpeaking() async {
    await _audioPlayer.stop();
    isPlaying = false;
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _ttsService.cleanupSession();
  }
}
