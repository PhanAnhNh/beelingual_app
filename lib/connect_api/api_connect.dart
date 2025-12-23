import 'dart:async';
import 'dart:convert';
import 'package:beelingual/app_UI/account/logIn.dart';
import 'package:beelingual/component/profileProvider.dart';
import 'package:beelingual/component/vocabularyProvider.dart';
import 'package:beelingual/model/model_Topic.dart';
import 'package:beelingual/model/model_Vocab.dart';
import 'package:beelingual/model/useVocabulary.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

import 'url.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  // --- 1. XỬ LÝ ĐĂNG NHẬP ---
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

  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool isValidUsername(String username) {
    final usernameRegex = RegExp(r'^\S+$');
    return usernameRegex.hasMatch(username);
  }

  bool isValidPassword(String password) {
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{6,24}$',
    );
    return passwordRegex.hasMatch(password);
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

  // Thay dòng cũ bằng dòng này:
  SupabaseClient get supabase => Supabase.instance.client;
  Future<AuthResponse> signUpSupabase({
    required String email,
    required String password,
  }) async {
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    return res;
  }


  // --- 2. LƯU TOKEN ---
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // Lưu thống nhất tên là 'accessToken'
    await prefs.setString('accessToken', accessToken);
    if (refreshToken.isNotEmpty) {
      await prefs.setString('refreshToken', refreshToken);
    }
    print("Đã lưu Session mới: $accessToken");
  }

  // --- 3. LẤY TOKEN (TOKEN GETTER) ---
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  // --- 4. REFRESH TOKEN (Tự động gia hạn) ---
  Future<bool> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');

    // Nếu không có refreshToken thì chịu, phải đăng nhập lại
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final url = Uri.parse('$urlAPI/api/refresh-token'); // Check lại endpoint server của bạn
    try {
      print("Đang thử Refresh Token...");
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final newAccess = data['token'] ?? data['accessToken']; // Check cả 2 key

        if (newAccess != null) {
          await prefs.setString('accessToken', newAccess);
          print("Refresh Token thành công!");
          return true;
        }
      }
    } catch (e) {
      print("Lỗi Refresh token: $e");
    }
    return false;
  }

  // --- 5. ĐĂNG XUẤT ---
  // Trong SessionManager -> logout
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context.mounted) {
      // Dùng pushAndRemoveUntil để xóa hết các màn hình trước đó (bao gồm bottom nav)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PageLogIn()), // Chuyển về trang Login full màn hình
            (Route<dynamic> route) => false, // false nghĩa là xóa hết lịch sử cũ
      );
    }
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
}

Future<Map<String, dynamic>?> fetchUserProfile(BuildContext context) async {
  // 1. Kiểm tra lại đường dẫn này với Backend của bạn.

  final url = Uri.parse('$urlAPI/api/profile');
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

    print("Profile Status Code: ${res.statusCode}");
    print("Profile Body: ${res.body}");
    // Xử lý hết hạn token (401)
    if (res.statusCode == 401) {
      print("Token hết hạn, đang thử refresh...");
      bool refreshed = await session.refreshAccessToken();
      if (refreshed) {
        token = await session.getAccessToken();
        res = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print("Retry Profile Status: ${res.statusCode}");
        print("Retry Profile Body: ${res.body}");
      } else {
        session.logout(context);
        return null;
      }
    }

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      print("Lỗi API: Server trả về code ${res.statusCode}");
    }
  } catch (e) {
    print("Lỗi Exception lấy User Profile: $e");
  }
  return null;
}
Future<List<Topic>> fetchTopics([BuildContext? context]) async {
  final url = Uri.parse('$urlAPI/api/topics');
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

    if (res.statusCode == 401) {
      print("Token hết hạn (401). Đang thử gia hạn...");
      final refreshSuccess = await session.refreshAccessToken();

      if (refreshSuccess) {
        token = await session.getAccessToken();
        res = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } else {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Phiên đăng nhập hết hạn")),
          );
          session.logout(context);
        }
        return [];
      }
    }

    // Xử lý kết quả (200 OK)
    if (res.statusCode == 200) {
      final dynamic decoded = json.decode(res.body);

      List<dynamic> listJson;

      // ⚠️ XỬ LÝ CẢ 2 TRƯỜNG HỢP:
      if (decoded is Map<String, dynamic>) {
        // Trường hợp 1: Có cấu trúc { data: [...] }
        if (decoded.containsKey('data')) {
          listJson = decoded['data'];
        } else {
          // Nếu không có key 'data', có thể toàn bộ response là array?
          print("API trả về Map nhưng không có key 'data'");
          return [];
        }
      } else if (decoded is List) {
        // Trường hợp 2: API trả về trực tiếp mảng []
        listJson = decoded;
      } else {
        print("API trả về kiểu dữ liệu không xác định: ${decoded.runtimeType}");
        return [];
      }

      return listJson.map((e) => Topic.fromJson(e)).toList();
    } else {
      print("Lỗi lấy data: ${res.statusCode} - ${res.body}");
      return [];
    }
  } catch (e) {
    print("Error fetchTopics: $e");
    return [];
  }
}

Future<List<Vocabulary>> fetchVocabulariesByTopic(String topicId, String level, [BuildContext? context]) async {
  // LƯU Ý: Kiểm tra lại đường dẫn API của bạn.
  // Ví dụ: /api/vocabularies?topicId=... hoặc /api/topics/:id/vocabularies
  // Dựa vào JSON Postman bạn gửi, mình đoán endpoint lọc theo query param
  final url = Uri.parse('$urlAPI/api/vocab?topic=$topicId&level=$level&limit=1000');

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
      print("Token hết hạn khi lấy từ vựng. Đang refresh...");
      final refreshSuccess = await session.refreshAccessToken();

      if (refreshSuccess) {
        token = await session.getAccessToken();
        res = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } else {
        if (context != null && context.mounted) {
          session.logout(context);
        }
        return [];
      }
    }

    if (res.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(res.body);
      // Dựa vào JSON Postman: data nằm trong key "data"
      final List<dynamic> listData = jsonResponse['data'];

      return listData.map((item) => Vocabulary.fromJson(item)).toList();
    } else {
      print("Lỗi lấy vocab: ${res.statusCode} - ${res.body}");
      return [];
    }
  } catch (e) {
    print("Exception fetchVocabularies: $e");
    return [];
  }
}

Future<bool> addVocabularyToDictionary(String vocabularyId, BuildContext context) async {
  // ⚠️ THAY ĐỔI ENDPOINT NÀY NẾU BACKEND CỦA BẠN KHÁC
  final url = Uri.parse('$urlAPI/api/user-vocabulary/add');
  final session = SessionManager();

  try {
    String? token = await session.getAccessToken();

    // 1. Gửi yêu cầu POST với ID từ vựng
    var res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'vocabularyId': vocabularyId}), // Gửi ID của từ vựng
    );

    // 2. Xử lý hết hạn token (401)
    if (res.statusCode == 401) {
      bool refreshed = await session.refreshAccessToken();
      if (refreshed) {
        token = await session.getAccessToken();
        // Thử lại lần 2
        res = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'vocabularyId': vocabularyId}),
        );
      } else {
        // Nếu không refresh được, thoát khỏi màn hình
        if (context.mounted) session.logout(context);
        return false;
      }
    }

    // 3. Xử lý kết quả
    if (res.statusCode == 200) {
      // 200: Thành công (đã thêm/đã tồn tại)

      // ✨ THAY ĐỔI: Tự động cập nhật Provider sau khi thêm thành công
      if (context.mounted) {
        Provider.of<UserVocabularyProvider>(context, listen: false).reloadVocab(context);
      }

      return true;
    } else if (res.statusCode == 400) {
      // Xử lý lỗi validation (ví dụ: thiếu ID)
      final errorData = jsonDecode(res.body);
      print("Lỗi API (400): ${errorData['message']}");
    } else {
      print("Lỗi API: Server trả về code ${res.statusCode}");
    }
  } catch (e) {
    print("Lỗi Exception khi thêm từ điển: $e");
  }
  return false;
}

Future<List<UserVocabularyItem>> fetchUserDictionary([BuildContext? context]) async {
  // ⚠️ THAY ĐỔI ENDPOINT NÀY NẾU BACKEND CỦA BẠN KHÁC
  final url = Uri.parse('$urlAPI/api/user-vocabulary');
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

    // Xử lý 401 và Refresh Token (giống như các hàm fetch khác của bạn)
    if (res.statusCode == 401) {
      final refreshSuccess = await session.refreshAccessToken();
      if (refreshSuccess) {
        token = await session.getAccessToken();
        res = await http.get(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
      } else {
        if (context != null && context.mounted) session.logout(context);
        return [];
      }
    }

    if (res.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(res.body);
      final List<dynamic> listData = jsonResponse['data'];

      return listData.map((item) => UserVocabularyItem.fromJson(item)).toList();
    } else {
      print("Lỗi lấy từ điển cá nhân: ${res.statusCode} - ${res.body}");
      return [];
    }
  } catch (e) {
    print("Exception fetchUserDictionary: $e");
    return [];
  }
}

Future<bool> deleteVocabularyFromDictionary(String userVocabId, BuildContext context) async {
  // ⚠️ THAY ĐỔI ENDPOINT NẾU BACKEND CỦA BẠN KHÁC (DELETE /api/user-vocabulary/:id)
  final url = Uri.parse('$urlAPI/api/user-vocabulary/$userVocabId');
  final session = SessionManager();

  try {
    String? token = await session.getAccessToken();

    var res = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // Xử lý 401 và Refresh Token (Tương tự các hàm khác)
    if (res.statusCode == 401) {
      bool refreshed = await session.refreshAccessToken();
      if (refreshed) {
        token = await session.getAccessToken();
        res = await http.delete(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
      } else {
        session.logout(context);
        return false;
      }
    }

    if (res.statusCode == 200) {
      return true; // Xóa thành công
    } else {
      print("Lỗi API khi xóa: ${res.statusCode} - ${res.body}");
      return false;
    }
  } catch (e) {
    print("Lỗi Exception khi xóa từ điển: $e");
    return false;
  }
}

Future<bool> updateUserInfo({
  required String fullName,
  required String email,
  required String level, // Tên tham số đã đổi
  required BuildContext context,
}) async {

  final url = Uri.parse('$urlAPI/api/profile');
  final session = SessionManager();

  try {
    String? token = await session.getAccessToken();
    var res = await http.put( // Hoặc PATCH
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fullname': fullName, // Chỉnh sửa
        'email': email,       // Chỉnh sửa
        'level': level,       // Giữ nguyên (nếu API yêu cầu)
      }),
    );

    if (res.statusCode == 401) {
      final refreshSuccess = await session.refreshAccessToken();
      if (refreshSuccess) {
        token = await session.getAccessToken();
        res = await http.put(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'fullname': fullName, 'email': email, 'level': level}));
      } else {
        session.logout(context);
        return false;
      }
    }
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thông tin thành công!")));

      // ✨ THAY ĐỔI: KÍCH HOẠT CẬP NHẬT TÊN NGƯỜI DÙNG ✨
      if (context.mounted) {
        // Gọi Provider để cập nhật tên người dùng ngay lập tức
        Provider.of<UserProfileProvider>(context, listen: false).updateFullname(fullName);
      }

      return true;
    } else {
      return false;
    }
  } catch (e) {
    print("Lỗi Exception khi cập nhật: $e");
    return false;
  }


}
Future<Map<String, dynamic>> changePasswordAPI(
    String currentPassword, String newPassword, BuildContext context) async {

  // 1. Lấy URL (Lưu ý: kiểm tra kỹ prefix đường dẫn router của bạn, ví dụ: /api/user/change-password)
  final url = Uri.parse('$urlAPI/api/change-password');

  final session = SessionManager();

  try {
    // 2. Lấy token
    String? token = await session.getAccessToken();

    // 3. Gọi API method PUT
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    // 4. Xử lý phản hồi
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Thành công
      return {'success': true, 'message': data['message'] ?? 'Đổi mật khẩu thành công'};
    } else if (response.statusCode == 401) {
      // Token hết hạn -> Xử lý refresh token hoặc logout ở đây (tùy logic app bạn)
      // Ví dụ đơn giản:
      return {'success': false, 'message': 'Phiên đăng nhập hết hạn'};
    } else {
      // Lỗi từ backend (400, 404...)
      return {'success': false, 'message': data['message'] ?? 'Lỗi không xác định'};
    }
  } catch (e) {
    print("Lỗi đổi mật khẩu: $e");
    return {'success': false, 'message': 'Lỗi kết nối máy chủ'};
  }
}