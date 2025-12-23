import 'dart:convert';
import 'package:beelingual/connect_api/api_connect.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'url.dart';

class StreakService {
  Future<Map<String, dynamic>> getMyStreak() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken'); // Lấy token đã lưu khi login

      final response = await http.get(
        Uri.parse('$urlAPI/api/my-streak'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Trả về { "current": X, "longest": Y }
      } else {
        print("Lỗi lấy streak: ${response.body}");
        return {"current": 0, "longest": 0};
      }
    } catch (e) {
      print("Lỗi kết nối streak: $e");
      return {"current": 0, "longest": 0};
    }
  }

  Future<void> updateStreak(BuildContext context) async {
    final session = SessionManager();
    String? token = await session.getAccessToken();

    // API POST mà bạn đã test trên Postman
    final url = Uri.parse('$urlAPI/api/streak');

    try {
      final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          // Body rỗng vì backend tự lấy userId từ Token (theo logic backend bạn gửi trước đó)
          body: jsonEncode({})
      );

      if (response.statusCode == 200) {
        print("🔥 Đã cập nhật Streak thành công!");
        print("Response: ${response.body}");
      } else if (response.statusCode == 401) {
        // Xử lý hết hạn token nếu cần
        print("⚠️ Token hết hạn khi update streak");
        // Có thể gọi refresh token ở đây nếu muốn logic chặt chẽ hơn
      } else {
        print("⚠️ Lỗi update streak: ${response.body}");
      }
    } catch (e) {
      print("❌ Lỗi kết nối khi update streak: $e");
    }
  }
}
