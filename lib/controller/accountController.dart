import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../logIn.dart';

final urlAPI = 'https://english-app-mupk.onrender.com';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  Timer? _tokenRefreshTimer;

  Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$urlAPI/api/login');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        print(data);
        if (accessToken != null && refreshToken != null) {
          await saveSession(accessToken: accessToken, refreshToken: refreshToken);
          return data;
        }
      }
      print("Login thất bại: ${res.body}");
      return null;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> signUp({
    required String username,
    required String email,
    required String fullname,
    required String password,
    required String role,
  }) async {
    final url = Uri.parse('$urlAPI/api/register');
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'fullname': fullname,
          'password': password,
          'role': role,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      } else {
        return {
          "error": true,
          "message": jsonDecode(res.body)["message"] ?? "Lỗi không xác định"
        };
      }
    } catch (e) {
      return {"error": true, "message": "Không thể kết nối server!"};
    }
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
    _scheduleTokenRefresh();
  }

  Future<void> logout(BuildContext context) async {
    _tokenRefreshTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => PageLogIn()),
          (route) => false,
    );
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');
    return accessToken != null && refreshToken != null;
  }

  Future<void> checkLoginStatus(BuildContext context) async {
    final loggedIn = await isLoggedIn();
    if (!loggedIn) {
      await logout(context);
    }
  }

  Future<bool> refreshAccessToken() async {
    final loggedIn = await isLoggedIn();
    if (!loggedIn) return false;

    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) return false;

    final url = Uri.parse('$urlAPI/api/refresh-token');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final newAccess = data['accessToken'];
        final newRefresh = data['refreshToken'] ?? refreshToken;

        if (newAccess == null) return false;

        await saveSession(accessToken: newAccess, refreshToken: newRefresh);
        return true;
      }
    } catch (e) {
      print("Refresh token error: $e");
    }

    return false;
  }

  void _scheduleTokenRefresh() {
    _tokenRefreshTimer?.cancel();

    _tokenRefreshTimer = Timer(const Duration(minutes: 15), () async {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) return; // User đã logout

      bool ok = await refreshAccessToken();
      if (ok) {
        print("Access token được refresh tự động.");
        _scheduleTokenRefresh(); // Lặp lại
      } else {
        print("Refresh token thất bại. Có thể logout user tự động.");
      }
    });
  }

  // --- GET ACCESS TOKEN (tự refresh nếu cần) ---
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    if (token == null) return null;

    // Optional: refresh token trước khi trả về
    await refreshAccessToken();
    token = prefs.getString('accessToken');
    return token;
  }
}
