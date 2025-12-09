import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/topic.dart';

final urlAPI ='https://english-app-mupk.onrender.com';

Future<List<Topic>> fetchAllTopic() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken');

  if (token == null) {
    throw Exception('Token không tồn tại. Vui lòng đăng nhập.');
  }

  int page = 1;
  int totalPages = 1;
  List<Topic> allTopic = [];

  do {
    final url = Uri.parse('$urlAPI/api/topics?page=$page&limit=10');
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
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Dữ liệu trả về không đúng định dạng JSON object');
    }

    totalPages = decoded['totalPages'] ?? 1;

    final List<dynamic> dataList = decoded['data'];
    if (dataList == null || dataList is! List) {
      throw Exception('Dữ liệu "data" không tồn tại hoặc không phải List');
    }

    allTopic.addAll(
      dataList.map((item) => Topic.fromJson(item)).toList(),
    );

    page++;
  } while (page <= totalPages);

  return allTopic;
}
