import 'dart:convert';
import 'package:beelingual_app/model/model_grammar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final urlAPI ='https://english-app-mupk.onrender.com';

Future<List<Category>> fetchAllCategory() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken');

  if (token == null) {
    throw Exception('Token không tồn tại. Vui lòng đăng nhập.');
  }

  final url = Uri.parse('$urlAPI/api/grammar-categories');
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

  // Decode JSON
  final decoded = json.decode(response.body);
  if (decoded is! List) {
    throw Exception('Dữ liệu trả về không đúng định dạng JSON array');
  }

  // Map từng item thành Category
  final categories = decoded.map<Category>((item) => Category.fromJson(item)).toList();

  return categories;
}

Future<List<Grammar>> fetchAllGrammarByCategory(String categoryId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken');

  if (token == null) {
    throw Exception('Token không tồn tại. Vui lòng đăng nhập.');
  }

  int page = 1;
  int totalPages = 1;
  List<Grammar> allGrammar = [];

  do {
    final url = Uri.parse('$urlAPI/api/grammar?page=$page&limit=10');
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
    final Map<String, dynamic> jsonData = decoded;

    totalPages = jsonData['totalPages'] ?? 1;

    final dataList = jsonData['data'];
    if (dataList == null || dataList is! List) {
      throw Exception('Dữ liệu "data" không tồn tại hoặc không phải List');
    }

    final grammarPage = dataList.map<Grammar>((item) => Grammar.fromJson(item)).toList();

    allGrammar.addAll(grammarPage);
    page++;
  } while (page <= totalPages);

  // Lọc theo categoryId
  return allGrammar.where((g) => g.category == categoryId).toList();
}
