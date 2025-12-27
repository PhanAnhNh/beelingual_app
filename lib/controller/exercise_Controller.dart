import 'dart:convert';
import 'package:beelingual/app_UI/Exe_UI/SummaryExeList.dart';
import 'package:beelingual/model/model_exercise.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../component/messDialog.dart';
import '../connect_api/url.dart';
import '../connect_api/tts_service.dart';

class ExerciseController {
  List<Exercises> exercises = [];
  Map<String, String> userAnswers = {};
  int currentIndex = 0;
  
  // TTS Service
  final TTSService _ttsService = TTSService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlayingGeminiAudio = false;

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
    
    // Get all listening exercise IDs
    final listeningIds = exercises
        .where((ex) => ex.skill == 'listening')
        .map((ex) => ex.id)
        .toList();
    
    // Prefetch ALL exercises (WAIT for completion)
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
    
    // Initialize TTS session and prefetch - WAIT for completion
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
    final bool isCorrect = userAnswer.trim().toLowerCase() ==
        ex.correctAnswer.trim().toLowerCase();

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

    // Cleanup session when finishing (delete all cached audio at once)
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



  /// Play listening exercise audio using Gemini TTS
  Future<void> speakLisExercises({
    required String exerciseId,
    required String audioUrl,
    required String level,
  }) async {
    if (audioUrl.isEmpty) return;

    // Stop if already playing
    if (isPlayingGeminiAudio) {
      await _audioPlayer.stop();
      isPlayingGeminiAudio = false;
      onAudioStateChange?.call();
      return;
    }

    try {
      isPlayingGeminiAudio = true;
      onAudioStateChange?.call();

      // Get audio source (Local cache or URL)
      final source = await _ttsService.getAudioSource(exerciseId);
      
      // Play audio from source
      if (source is DeviceFileSource) {
        await _audioPlayer.play(source);
      } else if (source is UrlSource) {
        await _audioPlayer.play(source);
      }

      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((_) {
        isPlayingGeminiAudio = false;
        onAudioStateChange?.call();
      });
      
    } catch (e) {
      print('❌ Error playing Gemini audio: $e');
      isPlayingGeminiAudio = false;
      onAudioStateChange?.call();
    }
  }
  
  /// Play audio for regular exercises (vocab, grammar)
  /// Uses same Gemini TTS but for question text
  Future<void> speakExercises(String exerciseId, String audioText) async {
    if (audioText.isEmpty) return;

    // Stop if already playing
    if (isPlayingGeminiAudio) {
      await _audioPlayer.stop();
      isPlayingGeminiAudio = false;
      onAudioStateChange?.call();
      return;
    }

    try {
      isPlayingGeminiAudio = true;
      onAudioStateChange?.call();

      // Get audio source (Local cache or URL)
      final source = await _ttsService.getAudioSource(exerciseId);
      
      // Play audio from source
      if (source is DeviceFileSource) {
        await _audioPlayer.play(source);
      } else if (source is UrlSource) {
        await _audioPlayer.play(source);
      }

      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((_) {
        isPlayingGeminiAudio = false;
        onAudioStateChange?.call();
      });
      
    } catch (e) {
      print('❌ Error playing audio: $e');
      isPlayingGeminiAudio = false;
      onAudioStateChange?.call();
    }
  }
  




  Future<void> stopSpeaking() async {
    await _audioPlayer.stop();
    isPlayingGeminiAudio = false;
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _ttsService.cleanupSession();
  }
}
