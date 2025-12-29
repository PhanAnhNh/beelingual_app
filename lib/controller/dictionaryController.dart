import 'package:flutter/material.dart';
import 'package:beelingual/component/vocabularyProvider.dart';
import 'package:provider/provider.dart';
import '../connect_api/api_connect.dart';
import '../model/useVocabulary.dart';

class DictionaryController {
  final Set<String> selectedVocabIds = {};
  String searchQuery = "";

  void updateSearchQuery(String query) {
    searchQuery = query.trim().toLowerCase();
  }

  List<UserVocabularyItem> filterVocabList(List<UserVocabularyItem> vocabList) {
    if (searchQuery.isEmpty) return vocabList;
    return vocabList.where((v) =>
    v.word.toLowerCase().contains(searchQuery) ||
        v.meaning.toLowerCase().contains(searchQuery) ||
        v.pronunciation.toLowerCase().contains(searchQuery)
    ).toList();
  }

  void toggleSelection(String vocabId) {
    if (selectedVocabIds.contains(vocabId)) {
      selectedVocabIds.remove(vocabId);
    } else {
      selectedVocabIds.add(vocabId);
    }
  }

  bool isSelected(String vocabId) {
    return selectedVocabIds.contains(vocabId);
  }

  void clearSelection() {
    selectedVocabIds.clear();
  }

  Future<void> refreshData(BuildContext context) async {
    Provider.of<UserVocabularyProvider>(context, listen: false).reloadVocab(context);
    clearSelection();
  }

  Future<void> deleteSelected(BuildContext context, Function showSnackBar) async {
    if (selectedVocabIds.isEmpty) {
      showSnackBar("Vui lòng chọn từ vựng để xóa.", const Color(0xFFFFA000));
      return;
    }

    final int countToDelete = selectedVocabIds.length;
    final bool? confirm = await showDeleteConfirmDialog(context, countToDelete);

    if (confirm == true) {
      await performDelete(context, countToDelete, showSnackBar);
    }
  }

  Future<bool?> showDeleteConfirmDialog(BuildContext context, int count) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              "Xác nhận xóa",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF5D4037)),
            ),
          ],
        ),
        content: Text(
          "Bạn có chắc chắn muốn xóa $count từ vựng đã chọn?",
          style: TextStyle(fontSize: 16, color: const Color(0xFF5D4037).withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Hủy", style: TextStyle(fontSize: 16, color: const Color(0xFF5D4037).withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text("Xóa", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> performDelete(BuildContext context, int countToDelete, Function showSnackBar) async {
    showSnackBar("Đang xóa $countToDelete từ vựng...", const Color(0xFFFFA000));

    bool allSuccess = true;
    List<String> successfullyDeleted = [];

    for (var vocabId in List.from(selectedVocabIds)) {
      final success = await deleteVocabularyFromDictionary(vocabId, context);
      if (success) {
        successfullyDeleted.add(vocabId);
      } else {
        allSuccess = false;
      }
    }

    selectedVocabIds.removeAll(successfullyDeleted);

    showSnackBar(
      allSuccess
          ? "Đã xóa thành công $countToDelete từ vựng."
          : "Đã xóa ${successfullyDeleted.length} từ. Một số không thể xóa.",
      allSuccess ? const Color(0xFF4CAF50) : const Color(0xFFFFA000),
    );

    // Reload dữ liệu sau khi xóa
    await refreshData(context);
  }
}
