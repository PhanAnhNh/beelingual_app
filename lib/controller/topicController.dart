import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../connect_api/url.dart';
import '../model/model_topicExe.dart';

Future<List<Topic>> fetchAllTopic() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken');

  if (token == null) {
    throw Exception('Token không tồn tại. Vui lòng đăng nhập.');
  }

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
      return [];
    }
    return dataList.map((item) => Topic.fromJson(item)).toList();
  }

  else {
    throw Exception('Dữ liệu trả về không đúng định dạng (không phải List hoặc Object)');
  }
}