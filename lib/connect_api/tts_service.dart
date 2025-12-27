import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'url.dart';

/// TTS Service for Gemini-powered audio generation
/// Manages audio caching and smart prefetching
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  String? _sessionId;
  String? _userId;

  /// Initialize session with user ID
  Future<void> initSession(String userId) async {
    _userId = userId;
    _sessionId = '$userId-${DateTime.now().millisecondsSinceEpoch}';
    print('🔑 TTS Session initialized: $_sessionId');
  }

  /// Get session ID (create if not exists)
  Future<String> getSessionId() async {
    if (_sessionId == null) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? 'guest';
      await initSession(userId);
    }
    return _sessionId!;
  }

  /// Get audio URL for an exercise
  Future<String> getAudioUrl(String exerciseId) async {
    final sessionId = await getSessionId();
    return '$urlAPI/api/tts/audio/$exerciseId?sessionId=$sessionId';
  }

  // Cache directory path (in memory for web, or file path for mobile)
  String? _cachePath;

  /// Get audio source for exercise
  /// Checks local cache first, then downloads if needed
  Future<Source> getAudioSource(String exerciseId) async {
    // Web support: Return URL source directly (browser handles caching)
    if (kIsWeb) {
      final url = await getAudioUrl(exerciseId);
      return UrlSource(url);
    }

    try {
      final file = await _getLocalFile(exerciseId);
      
      if (await file.exists()) {
        print('✅ Playing from local cache: ${file.path}');
        return DeviceFileSource(file.path);
      }

      // Download and save
      print('⬇️ Downloading audio for $exerciseId...');
      final url = await getAudioUrl(exerciseId);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('💾 Saved to local cache: ${file.path}');
        return DeviceFileSource(file.path);
      } else {
        throw Exception('Download failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Audio cache error: $e');
      // Fallback to URL
      final url = await getAudioUrl(exerciseId);
      return UrlSource(url);
    }
  }

  /// Get local file reference
  Future<File> _getLocalFile(String exerciseId) async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/tts_$exerciseId.wav');
  }

  /// Prefetch listening exercises
  /// Strategy: Wait for first 3 files (Critical), then download rest in background
  Future<void> prefetchAll(List<String> exerciseIds) async {
    if (exerciseIds.isEmpty) return;
    
    // 1. Download Initial Batch (Wait for this to complete)
    final firstBatchSize = 1;
    final initialCount = (exerciseIds.length < firstBatchSize) ? exerciseIds.length : firstBatchSize;
    final initialBatch = exerciseIds.sublist(0, initialCount);
    
    print('⏳ Downloading initial batch ($initialCount files)...');
    await Future.wait(initialBatch.map((id) => _downloadFile(id)));
    print('✅ Initial audio ready! Entering exercise...');
    
    // 2. Download Remaining (Background - Fire & Forget)
    if (exerciseIds.length > firstBatchSize) {
      final remaining = exerciseIds.sublist(firstBatchSize);
      _downloadBackground(remaining);
    }
  }

  /// Process remaining files in background
  Future<void> _downloadBackground(List<String> ids) async {
    print('🚀 Starting background download for remaining ${ids.length} files...');
    
    final batchSize = 3;
    for (var i = 0; i < ids.length; i += batchSize) {
      final end = (i + batchSize < ids.length) ? i + batchSize : ids.length;
      final batch = ids.sublist(i, end);
      
      await Future.wait(batch.map((id) => _downloadFile(id)));
    }
    print('✅ All background files downloaded');
  }

  /// Helper to download single file
  Future<void> _downloadFile(String exerciseId) async {
    try {
      final url = await getAudioUrl(exerciseId);
      
      // On Web: Just make the request to warm up browser cache
      if (kIsWeb) {
        await http.get(Uri.parse(url));
        print('✅ [Web] Cached: $exerciseId');
        return;
      }

      // On Mobile: Save to file
      final file = await _getLocalFile(exerciseId);
      if (await file.exists()) return; // Skip if already cached

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('✅ [Mobile] Downloaded: $exerciseId');
      }
    } catch (e) {
      print('⚠️ Failed to download $exerciseId: $e');
    }
  }

  /// Cleanup (Delete all cached files)
  Future<void> cleanupSession() async {
    _sessionId = null;
    print('🧹 Session Cleared (ID reset)');

    if (kIsWeb) {
      print('🧹 [Web] Browser cache will be managed by browser policy');
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final files = await dir.list().toList(); // Async list
      
      int count = 0;
      for (var file in files) {
        if (file.path.contains('tts_')) {
          await file.delete();
          count++;
        }
      }
      print('🧹 [Mobile] Deleted $count local audio files');
    } catch (e) {
      print('❌ Cleanup error: $e');
    }
  }
}
