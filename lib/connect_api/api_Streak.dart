import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../component/profileProvider.dart';
import 'api_connect.dart';
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
        return jsonDecode(response.body);
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
    final url = Uri.parse('$urlAPI/api/streak');

    try {
      final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({})
      );

      if (response.statusCode == 200) {
        print("🔥 Đã cập nhật Streak thành công!");

        // --- ĐOẠN CODE QUAN TRỌNG ĐỂ CẬP NHẬT GIAO DIỆN NGAY ---
        if (context.mounted) {
          final responseData = jsonDecode(response.body);
          // Giả sử server trả về số streak mới trong responseData['newStreak']
          // Nếu server không trả về số cụ thể, bạn có thể tự +1 vào streak hiện tại

          final provider = Provider.of<UserProfileProvider>(context, listen: false);

          // Cách 1: Tự cộng 1 (Optimistic UI)
          provider.updateLocalStreak(provider.currentStreak + 1);

          // Cách 2: (An toàn hơn) Gọi hàm sync ngầm
          // provider.syncProfileInBackground(context);
        }
        // --------------------------------------------------------

      } else {
        print("⚠️ Lỗi update streak: ${response.body}");
      }
    } catch (e) {
      print("❌ Lỗi kết nối khi update streak: $e");
    }
  }
}
