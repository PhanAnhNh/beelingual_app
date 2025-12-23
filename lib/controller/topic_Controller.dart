import 'dart:convert';
import 'package:beelingual/model/model_topicExe.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../connect_api/url.dart';

Future<List<Topic>> fetchAllTopic() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken');

  if (token == null) {
    throw Exception('Token không tồn tại. Vui lòng đăng nhập.');
  }

  List<Topic> allTopic = [];

  final url = Uri.parse('$urlAPI/api/topics');
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Không lấy được dữ liệu, status code: ${response.statusCode}');
  }

  final decoded = json.decode(response.body);

  if (decoded is List) {
    return decoded.map((item) => Topic.fromJson(item)).toList();
  }

  else if (decoded is Map<String, dynamic>) {
    final List<dynamic>? dataList = decoded['data'];
    if (dataList == null) {
      return []; // Hoặc throw lỗi nếu bắt buộc có data
    }
    return dataList.map((item) => Topic.fromJson(item)).toList();
  }

  else {
    throw Exception('Dữ liệu trả về không đúng định dạng (không phải List hoặc Object)');
  }
}