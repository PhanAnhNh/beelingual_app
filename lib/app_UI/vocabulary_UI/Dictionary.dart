import 'dart:async';
import 'package:beelingual/app_UI/account/pageAccount.dart';
import 'package:beelingual/component/vocabularyProvider.dart';
import 'package:beelingual/model/useVocabulary.dart';
import 'package:flutter/material.dart';
import 'package:beelingual/connect_api/api_connect.dart';
import 'package:provider/provider.dart';
import 'package:beelingual/controller/exercise_Controller.dart';

class VocabularyLearnedScreen extends StatefulWidget {
  const VocabularyLearnedScreen({super.key});

  @override
  State<VocabularyLearnedScreen> createState() => _VocabularyLearnedScreenState();
}

class _VocabularyLearnedScreenState extends State<VocabularyLearnedScreen>
    with SingleTickerProviderStateMixin {
  Set<String> _selectedVocabIds = {};
  final ExerciseController exerciseController = ExerciseController();
  late AnimationController _animationController;

  // Theme Colors
  static const Color honeyYellow = Color(0xFFFFB800);
  static const Color goldenAmber = Color(0xFFFFA000);
  static const Color darkHoney = Color(0xFF8B6914);
  static const Color creamWhite = Color(0xFFFFFDF5);
  static const Color warmBrown = Color(0xFF5D4037);
  static const Color lightHoneycomb = Color(0xFFFFF3CD);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _refreshData(BuildContext context) {
    Provider.of<UserVocabularyProvider>(context, listen: false).reloadVocab(context);
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

  Future<void> _handleRefresh() async {
    await Provider.of<UserVocabularyProvider>(context, listen: false)
        .reloadVocab(context);
  }

  Future<void> _handleDeleteSelected() async {
    if (_selectedVocabIds.isEmpty) {
      _showSnackBar("Vui lòng chọn từ vựng để xóa.", goldenAmber);
      return;
    }

    final int countToDelete = _selectedVocabIds.length;
    final bool? confirm = await _showDeleteConfirmDialog(countToDelete);

    if (confirm == true) {
      await _performDelete(countToDelete);
    }
  }

  Future<bool?> _showDeleteConfirmDialog(int count) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: creamWhite,
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: warmBrown,
              ),
            ),
          ],
        ),
        content: Text(
          "Bạn có chắc chắn muốn xóa $count từ vựng đã chọn?",
          style: TextStyle(fontSize: 16, color: warmBrown.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Hủy",
              style: TextStyle(fontSize: 16, color: warmBrown.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text("Xóa", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(int countToDelete) async {
    _showSnackBar("Đang xóa $countToDelete từ vựng...", goldenAmber);

    bool allSuccess = true;
    List<String> successfullyDeleted = [];

    for (var userVocabId in List.from(_selectedVocabIds)) {
      final success = await deleteVocabularyFromDictionary(userVocabId, context);
      if (success) {
        successfullyDeleted.add(userVocabId);
      } else {
        allSuccess = false;
      }
    }

    setState(() {
      _selectedVocabIds.removeAll(successfullyDeleted);
    });

    _showSnackBar(
      allSuccess
          ? "Đã xóa thành công $countToDelete từ vựng."
          : "Đã xóa ${successfullyDeleted.length} từ. Một số không thể xóa.",
      allSuccess ? const Color(0xFF4CAF50) : goldenAmber,
    );

    _refreshData(context);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vocabProvider = Provider.of<UserVocabularyProvider>(context);
    final vocabList = vocabProvider.vocabList;
    final isLoading = vocabProvider.isLoading;

    return Scaffold(
      backgroundColor: creamWhite,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),

          if (vocabList.isNotEmpty)
            SliverToBoxAdapter(child: _buildSelectAllSection(vocabList)),

          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: honeyYellow, strokeWidth: 3),
              ),
            )
          else if (vocabList.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final vocab = vocabList[index];
                    final isSelected = _selectedVocabIds.contains(vocab.userVocabId);
                    return _buildVocabularyCard(context, vocab, isSelected, index);
                  },
                  childCount: vocabList.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: honeyYellow,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'Vocabulary learned',
          style: TextStyle(
            color: warmBrown,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFD54F), honeyYellow, goldenAmber],
            ),
          ),
        ),
      ),
      actions: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: _selectedVocabIds.isNotEmpty
                ? Colors.red.withOpacity(0.15)
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            icon: Icon(
              Icons.delete_rounded,
              color: _selectedVocabIds.isNotEmpty ? Colors.red.shade700 : warmBrown,
              size: 24,
            ),
            onPressed: _handleDeleteSelected,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectAllSection(List<UserVocabularyItem?> vocabList) {
    final isAllSelected = vocabList.isNotEmpty &&
        _selectedVocabIds.length == vocabList.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: honeyYellow.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: honeyYellow.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (isAllSelected) {
                  _selectedVocabIds.clear();
                } else {
                  _selectedVocabIds = vocabList.map((v) => v!.userVocabId).toSet();
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                gradient: isAllSelected
                    ? const LinearGradient(colors: [honeyYellow, goldenAmber])
                    : null,
                color: isAllSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAllSelected ? goldenAmber : warmBrown.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isAllSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Select all',
            style: TextStyle(color: warmBrown, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const Spacer(),
          if (_selectedVocabIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [honeyYellow, goldenAmber]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_selectedVocabIds.length} đã chọn',
                style: const TextStyle(color: warmBrown, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: honeyYellow.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.book_outlined, size: 64, color: goldenAmber),
          ),
          const SizedBox(height: 24),
          const Text(
            "Chưa có từ vựng nào",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: warmBrown),
          ),
          const SizedBox(height: 8),
          Text(
            "Hãy bắt đầu học để thêm từ vựng!",
            style: TextStyle(fontSize: 16, color: warmBrown.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyCard(
      BuildContext context,
      UserVocabularyItem vocab,
      bool isSelected,
      int index,
      ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (index * 40)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? lightHoneycomb : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? honeyYellow : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? honeyYellow.withOpacity(0.2) : Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _toggleSelection(vocab.userVocabId),
            splashColor: honeyYellow.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: () => _toggleSelection(vocab.userVocabId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(colors: [honeyYellow, goldenAmber])
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? goldenAmber : warmBrown.withOpacity(0.25),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                vocab.word,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: warmBrown,
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => exerciseController.speakExercises(vocab.word),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: honeyYellow.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.volume_up_rounded, color: darkHoney, size: 22),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          vocab.pronunciation,
                          style: TextStyle(
                            fontSize: 14,
                            color: darkHoney.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          vocab.meaning,
                          style: TextStyle(
                            fontSize: 16,
                            color: warmBrown.withOpacity(0.85),
                            height: 1.4,
                          ),
                        ),

                        if (vocab.type.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: honeyYellow.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              vocab.type,
                              style: TextStyle(
                                fontSize: 13,
                                color: darkHoney,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}