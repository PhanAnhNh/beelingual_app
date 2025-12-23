import 'dart:convert';
import 'package:beelingual/component/progressProvider.dart';
import 'package:http/http.dart' as http;
import 'package:beelingual/connect_api/api_connect.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'url.dart';

Future<Map<String, dynamic>?> fetchUserProgress(BuildContext context) async {
  final url = Uri.parse('$urlAPI/api/user-progress'); // Endpoint BE mới
  final session = SessionManager();

  try {
    String? token = await session.getAccessToken();

    var res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // Xử lý hết hạn token (401)
    if (res.statusCode == 401) {
      bool refreshed = await session.refreshAccessToken();
      if (refreshed) {
        token = await session.getAccessToken();
        res = await http.get(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
      } else {
        session.logout(context);
        return null;
      }
    }

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      // Giả định BE trả về { success: true, data: {...} }
      return data['data'];
    } else {
      print("Lỗi API lấy Progress: ${res.statusCode} - ${res.body}");
    }
  } catch (e) {
    print("Lỗi Exception lấy Progress: $e");
  }
  return null;
}

// api_connect.dart

Future<void> markVocabAsViewed(String vocabId, BuildContext context) async {
  final session = SessionManager();
  String? token = await session.getAccessToken();
  final url = Uri.parse('$urlAPI/api/detail_vocab/$vocabId');

  try {
    await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print("Đã đánh dấu xem từ: $vocabId");

    // THÊM DÒNG NÀY: Cập nhật progress ngay sau khi học từ
    if (context.mounted) {
      // Sử dụng Provider để cập nhật progress
      await Provider.of<UserProgressProvider>(context, listen: false)
          .fetchProgress(context);
    }

  } catch (e) {
    print("Lỗi đánh dấu xem từ: $e");
  }
}