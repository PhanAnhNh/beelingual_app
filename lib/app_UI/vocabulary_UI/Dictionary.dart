import 'dart:async';
import 'package:beelingual_app/app_UI/account/pageAccount.dart';
import 'package:beelingual_app/component/vocabularyProvider.dart';
import 'package:beelingual_app/model/useVocabulary.dart';
import 'package:flutter/material.dart';
import 'package:beelingual_app/connect_api/api_connect.dart';
import 'package:provider/provider.dart';

class VocabularyLearnedScreen extends StatefulWidget {
  const VocabularyLearnedScreen({super.key});

  @override
  State<VocabularyLearnedScreen> createState() => _VocabularyLearnedScreenState();
}

class _VocabularyLearnedScreenState extends State<VocabularyLearnedScreen> {
  Set<String> _selectedVocabIds = {};

  void _refreshData(BuildContext context) {
    // Chỉ cần gọi hàm reload trong Provider
    Provider.of<UserVocabularyProvider>(context, listen: false).reloadVocab(context);
    // Reset selection
    setState(() {
      _selectedVocabIds = {};
    });
  }

  void _toggleSelection(String userVocabId) {
    setState(() {
      if (_selectedVocabIds.contains(userVocabId)) {
        _selectedVocabIds.remove(userVocabId);
      } else {
        _selectedVocabIds.add(userVocabId);
      }
    });
  }

  // --- HÀM XỬ LÝ REFRESH KÉO XUỐNG ---
  Future<void> _handleRefresh() async {
    // Tải lại dữ liệu qua Provider
    await Provider.of<UserVocabularyProvider>(context, listen: false).reloadVocab(context);
    // Bạn có thể thêm logic kiểm tra session ở đây nếu cần
    // session.checkLoginStatus(context);
  }

  // Hàm xử lý xóa từ vựng đã chọn (Đã sửa logic xóa API)
  void _handleDeleteSelected() async {
    if (_selectedVocabIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn từ vựng để xóa.")),
      );
      return;
    }

    final int countToDelete = _selectedVocabIds.length;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc chắn muốn xóa $countToDelete từ vựng đã chọn khỏi từ điển không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đang xóa $countToDelete từ vựng...")),
      );

      bool allSuccess = true;
      List<String> successfullyDeleted = [];

      // Dùng List.from() để tránh lỗi khi _selectedVocabIds thay đổi trong vòng lặp
      for (var userVocabId in List.from(_selectedVocabIds)) {
        // ⚠️ GỌI HÀM API THẬT SỰ
        final success = await deleteVocabularyFromDictionary(userVocabId, context);

        if (success) {
          successfullyDeleted.add(userVocabId);
        } else {
          allSuccess = false;
        }
      }

      // Cập nhật lại danh sách chọn sau khi xóa thành công
      setState(() {
        _selectedVocabIds.removeAll(successfullyDeleted);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(allSuccess
            ? "Đã xóa thành công $countToDelete từ vựng."
            : "Đã xóa ${successfullyDeleted.length} từ vựng. Một số từ không thể xóa được."),
          backgroundColor: allSuccess ? Colors.green : Colors.orange,
        ),
      );
      _refreshData(context); // Tải lại dữ liệu sau khi hoàn tất
    }
  }


  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFFFFDE7);
    const Color cardColor = Color(0xFFFFF9C4);
    const Color startButtonColor = Color(0xFFB88F4F);
    const Color darkTextColor = Color(0xFF5D4037);

    final vocabProvider = Provider.of<UserVocabularyProvider>(context);
    final vocabList = vocabProvider.vocabList;
    final isLoading = vocabProvider.isLoading;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Color(0xFFFFE474),
        elevation: 0,
        title: const Text(
          'Vocabulary Learned',
          style: TextStyle(color: darkTextColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: darkTextColor),
            onPressed: _handleDeleteSelected,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.textDark,
        onRefresh: _handleRefresh,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          child: Column(
            children: [
              // Header: Select all (Đã sửa lỗi)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Checkbox(
                      // SỬ DỤNG _currentVocabList để kiểm tra trạng thái
                      value: vocabList.isNotEmpty &&
                          _selectedVocabIds.length == vocabList.length,
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedVocabIds = vocabList.map((v) => v.userVocabId).toSet();
                          } else {
                            _selectedVocabIds.clear();
                          }
                        });
                      },
                      activeColor: darkTextColor,
                    ),
                    const Text('Select all', style: TextStyle(color: darkTextColor, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),


              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (vocabList.isEmpty)
                const Center(child: Text("Bạn chưa có từ vựng nào trong từ điển cá nhân."))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vocabList.length,
                  itemBuilder: (context, index) {
                    final vocab = vocabList[index];
                    final isSelected = _selectedVocabIds.contains(vocab.userVocabId);

                    return _buildVocabularyListItem(
                        context,
                        vocab,
                        isSelected,
                        _toggleSelection,
                        darkTextColor,
                        cardColor,
                        startButtonColor
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVocabularyListItem(
      BuildContext context,
      UserVocabularyItem vocab,
      bool isSelected,
      Function(String) toggleSelection,
      Color darkTextColor,
      Color cardColor,
      Color startButtonColor,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng 1: Checkbox, Audio, Word, Meaning, Start Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (val) => toggleSelection(vocab.userVocabId),
                  activeColor: darkTextColor,
                ),
              ),
              const SizedBox(width: 8),

              // Icon Audio (Giả lập chức năng phát âm)
              Icon(Icons.volume_up, color: darkTextColor),
              const SizedBox(width: 12),

              // Word & Meaning
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vocab.word,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      vocab.pronunciation,
                      style: TextStyle(
                      fontSize: 14,
                      color: darkTextColor.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      vocab.meaning,
                      style: TextStyle(
                        fontSize: 14,
                        color: darkTextColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Hàng 2: Example/Trạng thái (theo mẫu ảnh)
          Padding(
            padding: const EdgeInsets.only(left: 44.0, top: 8.0), // Căn chỉnh với từ vựng
            child: Row(
              children: [
                Icon(Icons.volume_up, size: 18, color: darkTextColor), // Icon Audio cho ví dụ
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    // Ví dụ không có trong JSON bạn cung cấp, nên dùng tạm Loại từ và Trạng thái.
                    '(${vocab.type}) - Status: ${vocab.status}',
                    style: TextStyle(fontSize: 14, color: darkTextColor.withOpacity(0.7)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}