// beelingual_app/component/userProgressProvider.dart
import 'package:beelingual/connect_api/api_Progress.dart';
import 'package:flutter/material.dart';
import 'package:beelingual/connect_api/api_connect.dart';

class UserProgressProvider extends ChangeNotifier {
  String _currentLevel = "Level 1"; // Hoặc Level A
  double _topicProgressBarPercentage = 0.0;
  bool _isLoading = false;

  String get currentLevel => _currentLevel;
  double get topicProgressBarPercentage => _topicProgressBarPercentage;
  bool get isLoading => _isLoading;

  UserProgressProvider(BuildContext context) {
    // Khởi tạo và tải dữ liệu lần đầu
    Future.delayed(Duration.zero, () => fetchProgress(context, notifyOnStart: false));
  }

  Future<void> fetchProgress(BuildContext context, {bool notifyOnStart = true}) async {
    if (notifyOnStart) {
      _isLoading = true;
      Future.microtask(() => notifyListeners());
    }

    try {
      final progressData = await fetchUserProgress(context);

      if (progressData != null) {
        // --- LOGIC MỚI: Chỉ lấy phần trăm ---

        // Tiêu đề hiển thị (Thay cho "Level 1")
        _currentLevel = "Tổng quan";

        // Lấy phần trăm (key trả về từ backend là 'percent')
        // Lưu ý: Kiểm tra xem backend trả về key tên là 'percent' hay 'topicProgressBarPercentage'
        // Nếu dùng code backend mới ở trên thì key là 'percent'
        var rawPercent = progressData['percent'];

        if (rawPercent is num) {
          _topicProgressBarPercentage = rawPercent.toDouble();
        } else {
          _topicProgressBarPercentage = 0.0;
        }

      } else {
        _currentLevel = "Tổng quan";
        _topicProgressBarPercentage = 0.0;
      }
    } catch (e) {
      print("Error fetching progress: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Hàm được gọi khi có sự thay đổi (thêm từ, xóa từ)
  Future<void> reloadProgress(BuildContext context) async {
    await fetchProgress(context);
  }
}