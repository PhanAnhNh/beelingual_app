import 'dart:async';
import 'package:beelingual/component/vocabularyProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../controller/dictionaryController.dart';
import '../../model/useVocabulary.dart';

class VocabularyLearnedScreen extends StatefulWidget {
  const VocabularyLearnedScreen({super.key});

  @override
  State<VocabularyLearnedScreen> createState() => _VocabularyLearnedScreenState();
}

class _VocabularyLearnedScreenState extends State<VocabularyLearnedScreen>
    with SingleTickerProviderStateMixin {
  final DictionaryController _dictController = DictionaryController();
  late AnimationController _animationController;

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

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
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
    final filteredList =
    _dictController.filterVocabList(vocabList);

    return Scaffold(
      backgroundColor: lightHoneycomb,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),

          if (vocabList.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _dictController.searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search",
                    prefixIcon: const Icon(Icons.search),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

          // Select all box
          if (vocabList.isNotEmpty)
            SliverToBoxAdapter(child: _buildSelectAllSection(filteredList)),

          // Loading indicator
          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: honeyYellow, strokeWidth: 3),
              ),
            )
          // Empty state
          else if (vocabList.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          // Vocabulary list
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final vocab = filteredList[index];
                    final isSelected = _dictController.isSelected(vocab.userVocabId);
                    return _buildVocabularyCard(context, vocab, isSelected, index);
                  },
                  childCount: filteredList.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // AppBar với delete
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFFFF176),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text('Dictionary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.delete_rounded,
            color: _dictController.selectedVocabIds.isNotEmpty
                ? Colors.red.shade700
                : warmBrown,
            size: 24,
          ),
          onPressed: () => _dictController.deleteSelected(context, _showSnackBar),
        ),
      ],
    );
  }

  Widget _buildSelectAllSection(List<UserVocabularyItem?> vocabList) {
    final isAllSelected = vocabList.isNotEmpty &&
        _dictController.selectedVocabIds.length == vocabList.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: honeyYellow.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (isAllSelected) {
                  _dictController.clearSelection();
                } else {
                  _dictController.selectedVocabIds
                      .addAll(vocabList.map((v) => v!.userVocabId));
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
          const Text('Select all',
              style:
              TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const Spacer(),
          if (_dictController.selectedVocabIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Text('${_dictController.selectedVocabIds.length} đã chọn',
                  style: const TextStyle(
                      color: warmBrown, fontSize: 14, fontWeight: FontWeight.bold)),
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
            decoration:
            BoxDecoration(color: honeyYellow.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.book_outlined, size: 64, color: goldenAmber),
          ),
          const SizedBox(height: 24),
          const Text("Chưa có từ vựng nào",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: warmBrown)),
          const SizedBox(height: 8),
          Text("Hãy bắt đầu học để thêm từ vựng!",
              style: TextStyle(fontSize: 16, color: warmBrown.withOpacity(0.6))),
        ],
      ),
    );
  }

  // Vocabulary card
  Widget _buildVocabularyCard(
      BuildContext context, UserVocabularyItem vocab, bool isSelected, int index) {
    final AudioPlayer _audioPlayer = AudioPlayer();
    return GestureDetector(
      onTap: () {
        setState(() {
          _dictController.toggleSelection(vocab.userVocabId);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFFF176) : Colors.white70,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [honeyYellow, goldenAmber])
                      : null,
                  color: isSelected ? null : Colors.white70,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isSelected
                          ? goldenAmber
                          : warmBrown.withOpacity(0.25),
                      width: 2),
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white70, size: 18) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vocab.word,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold, color: warmBrown)),
                    const SizedBox(height: 6),
                    Text(vocab.pronunciation,
                        style: TextStyle(
                            fontSize: 14,
                            color: darkHoney.withOpacity(0.6),
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 10),
                    Text(vocab.meaning,
                        style: TextStyle(
                            fontSize: 16, color: warmBrown.withOpacity(0.85), height: 1.4)),
                  ],
                ),
              ),
              // IconButton(
              //   onPressed: () => {
              //     _audioPlayer.play(
              //       UrlSource(vocab.audioUrl),
              //     ),
              //     print('Link âm thanh: '+vocab.audioUrl)
              //   },
              //   icon: const Icon(Icons.volume_up_rounded, color: darkHoney),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
