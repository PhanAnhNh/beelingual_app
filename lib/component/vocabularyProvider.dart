import 'package:flutter/material.dart';
import 'package:beelingual/model/useVocabulary.dart';
import 'package:beelingual/connect_api/api_connect.dart'; // Chắc chắn đã import file này

class UserVocabularyProvider extends ChangeNotifier {
  // Danh sách từ vựng hiện tại
  List<UserVocabularyItem> _vocabList = [];
  bool _isLoading = false;

  List<UserVocabularyItem> get vocabList => _vocabList;
  bool get isLoading => _isLoading;

  // Constructor hoặc init để tải lần đầu
  UserVocabularyProvider(BuildContext context) {
    fetchVocab(context);
  }

  // --- Hàm tải dữ liệu API ---
  Future<void> fetchVocab(BuildContext context) async {
    if (_isLoading) return; // Tránh tải nhiều lần

    _isLoading = true;
    notifyListeners(); // Báo hiệu bắt đầu tải (để hiện CircularProgressIndicator)

    try {
      // Gọi hàm fetch API đã có
      final List<UserVocabularyItem> newData = await fetchUserDictionary(context);

      _vocabList = newData;
    } catch (e) {
      print("Error fetching vocabulary in provider: $e");
      // Xử lý lỗi nếu cần
    } finally {
      _isLoading = false;
      notifyListeners(); // Báo hiệu kết thúc tải và cập nhật UI
    }
  }

  // --- Hàm CẬP NHẬT TỨC THỜI (được gọi từ màn hình khác) ---
  // Khi bạn thêm/xóa từ ở màn hình khác, chỉ cần gọi hàm này:
  // Provider.of<UserVocabularyProvider>(context, listen: false).reloadVocab();
  Future<void> reloadVocab(BuildContext context) async {
    // Chỉ cần gọi lại hàm tải
    await fetchVocab(context);
  }
}