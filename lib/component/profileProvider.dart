import 'package:flutter/material.dart';
import 'package:beelingual/connect_api/api_connect.dart';
import 'package:beelingual/connect_api/api_Streak.dart'; // Đảm bảo import đúng file service streak

class UserProfileProvider extends ChangeNotifier {
  String _fullname = "Đang tải...";
  bool _isLoading = true;
  String? _email;
  String? _joinDate;

  // Biến streak
  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  String get fullname => _fullname;
  bool get isLoading => _isLoading;
  String? get email => _email;
  String? get joinDate => _joinDate;
  int _xp = 0;
  int get xp => _xp;

  final StreakService _streakService = StreakService();

  UserProfileProvider(BuildContext context) {
    fetchProfile(context);
  }

  Future<void> fetchProfile(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final profileData = await fetchUserProfile(context);

      if (profileData != null) {
        // Log để kiểm tra xem cấu trúc data thực tế là gì
        print("Data nhận được trong Provider: $profileData");

        final dynamic data = profileData['user'] ?? profileData['data'] ?? profileData;

        _fullname = data['fullname'] ?? "Người dùng";
        _email = data['email'];

        if (data['xp'] != null) {
          _xp = int.parse(data['xp'].toString());
        } else {
          _xp = 0;
        }

        // Xử lý ngày tham gia
        if (data['createdAt'] != null) {
          try {
            DateTime date = DateTime.parse(data['createdAt']);
            _joinDate = _formatDate(date);
          } catch (e) {
            _joinDate = "Không rõ";
          }
        } else {
          _joinDate = "Mới tham gia";
        }

        // --- SỬA Ở ĐÂY: LẤY STREAK TỪ DATA USER ---
        // Dựa vào log của bạn: "streak": { "current": 1 ... } nằm trong data
        if (data['streak'] != null && data['streak'] is Map) {
          // Ép kiểu dynamic sang int để tránh lỗi
          _currentStreak = int.parse(data['streak']['current'].toString());
          print("Đã cập nhật streak từ Profile: $_currentStreak");
        } else {
          print("Không tìm thấy streak trong user profile, sẽ gọi API riêng...");
          // Nếu trong user info không có, ta mới gọi API riêng để chữa cháy
          await _fetchStreakSeparately();
        }
        // ------------------------------------------

      } else {
        _fullname = "Không thể tải tên";
      }
    } catch(e) {
      print("Lỗi tải profile: $e");
      _fullname = "Lỗi kết nối";
    }

    _isLoading = false;
    notifyListeners();
  }

  // Tách hàm gọi streak riêng để code gọn hơn
  Future<void> _fetchStreakSeparately() async {
    try {
      final streakData = await _streakService.getMyStreak();
      _currentStreak = streakData['current'] ?? 0;
    } catch (e) {
      print("Lỗi lấy streak riêng lẻ: $e");
    }
  }

  // Hàm reloadProfile (khi kéo để refresh)
  Future<void> reloadProfile(BuildContext context) async {
    // Gọi lại fetchProfile để lấy toàn bộ thông tin mới nhất
    await fetchProfile(context);
  }

  String _formatDate(DateTime date) {
    return "${date.month} / ${date.year}";
  }

  void updateFullname(String newName) {
    _fullname = newName;
    notifyListeners();
  }
}