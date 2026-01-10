import 'package:beelingual_app/connect_api/api_Streak.dart';
import 'package:beelingual_app/connect_api/api_connect.dart';
import 'package:flutter/material.dart';

class UserProfileProvider extends ChangeNotifier {
  String _fullname = "Đang tải...";
  bool _isLoading = true;
  String? _email;
  String? _joinDate;
  int _xp = 0;
  int _currentStreak = 0;
  int _gems = 0;
  int get gems => _gems;

  String get fullname => _fullname;
  bool get isLoading => _isLoading;
  String? get email => _email;
  String? get joinDate => _joinDate;
  int get xp => _xp;
  int get currentStreak => _currentStreak;

  final StreakService _streakService = StreakService();

  UserProfileProvider();

  void setStreak(int newStreak) {
    if (_currentStreak != newStreak) {
      _currentStreak = newStreak;
      notifyListeners();
    }
  }

  void increaseGems(int amount) {
    _gems += amount;
    notifyListeners(); // Báo cho UI cập nhật ngay
  }

  void decreaseGems(int amount) {
    if (_gems >= amount) {
      _gems -= amount;
      notifyListeners();
    }
  }

  void increaseXP(int amount) {
    _xp += amount;
    notifyListeners();
  }

  void updateLocalStreak(int newStreak) {
    _currentStreak = newStreak;
    notifyListeners();
  }

  void clear() {
    _fullname = "Đang tải...";
    _email = null;
    _joinDate = null;
    _xp = 0;
    _gems = 0;
    _currentStreak = 0;
    _isLoading = true;
    notifyListeners();
  }

  Future<void> syncProfileInBackground(BuildContext context) async {
    try {
      print("Đang đồng bộ dữ liệu ngầm...");
      final profileData = await fetchUserProfile(context);

      if (profileData != null) {
        final dynamic data = profileData['user'] ?? profileData['data'] ?? profileData;

        if (data['xp'] != null) {
          _xp = int.parse(data['xp'].toString());
        }

        if (data['gems'] != null) {
          _gems = int.parse(data['gems'].toString());
        }

        if (data['streak'] != null && data['streak'] is Map) {
          _currentStreak = int.parse(data['streak']['current'].toString());
        }

        notifyListeners();
        print("✅ Đã đồng bộ xong: XP=$_xp, Gems=$_gems");
      }
    } catch (e) {
      print("❌ Lỗi sync background: $e");
    }
  }

  Future<void> fetchProfile(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final profileData = await fetchUserProfile(context);

      if (profileData != null) {
        final dynamic data = profileData['user'] ?? profileData['data'] ?? profileData;

        _fullname = data['fullname'] ?? "Người dùng";
        _email = data['email'];

        _xp = data['xp'] != null ? int.parse(data['xp'].toString()) : 0;
        _gems = data['gems'] != null ? int.parse(data['gems'].toString()) : 0;

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

        if (data['streak'] != null && data['streak'] is Map) {
          _currentStreak = int.parse(data['streak']['current'].toString());
        } else {
          await _fetchStreakSeparately();
        }
      } else {
        _fullname = "Không thể tải tên";
      }
    } catch (e) {
      print("Lỗi tải profile: $e");
      _fullname = "Lỗi kết nối";
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Reload profile (kéo để refresh)
  Future<void> reloadProfile(BuildContext context) async {
    await fetchProfile(context);
  }

  /// Gọi API streak riêng nếu không có trong profile
  Future<void> _fetchStreakSeparately() async {
    try {
      final streakData = await _streakService.getMyStreak();
      _currentStreak = streakData['current'] ?? 0;
    } catch (e) {
      print("Lỗi lấy streak riêng lẻ: $e");
      _currentStreak = 0;
    }
  }

  /// Cập nhật tên thủ công
  void updateFullname(String newName) {
    _fullname = newName;
    notifyListeners();
  }


  String _formatDate(DateTime date) {
    return "${date.month} / ${date.year}";
  }
}