import 'dart:convert';
import 'package:beelingual/connect_api/api_Progress.dart';
import 'package:beelingual/connect_api/api_Streak.dart';
import 'package:beelingual/connect_api/api_connect.dart';
import 'package:beelingual/model/model_Vocab.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../component/progressProvider.dart';
import '../../connect_api/url.dart';

class AppColors {
  static const Color background = Color(0xFFFFFDE7);
  static const Color cardBackground = Color(0xFFFFF9C4);
  static const Color cardSelected = Color(0xFFFCE79A);
  static const Color iconActive = Color(0xFFEBC934);
  static const Color textDark = Color(0xFF5D4037);

  static const Color textLight = Color(0xFFA68B7B);
  static const Color buttonBackground = Color(0xFFFDF1C8);
  static const Color progressBarTrack = Color(0xFFE0B769);
  static const Color progressBarFill = Color(0xFFFFFFFF);
}


class VocabularyCardScreen extends StatefulWidget {
  final String topicId;
  final String topicName;
  final String level;
  final VoidCallback? onProgressUpdated;

  const VocabularyCardScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.level,
    this.onProgressUpdated
  });

  @override
  State<VocabularyCardScreen> createState() => _VocabularyCardScreenState();
}

class _VocabularyCardScreenState extends State<VocabularyCardScreen> {
  List<Vocabulary> _vocabList = [];
  bool _isLoading = true;
  bool _isLoadingNext = false;
  int _currentIndex = 0;
  int _currentPage = 1;
  int _totalVocabs = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadInitialWord();
  }

  // LOAD 2 TỪ ĐẦU TIÊN (để người dùng không phải đợi khi bấm Next lần đầu)
  Future<void> _loadInitialWord() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _vocabList.clear();
    });

    final result = await fetchVocabulariesPaginated(
      topicId: widget.topicId,
      level: widget.level,
      page: 1,
      limit: 2,  // Load 2 từ thay vì 1
      context: context,
    );

    if (mounted) {
      setState(() {
        _vocabList = List<Vocabulary>.from(result['data']);
        _totalVocabs = result['total'] ?? 0;
        _isLoading = false;
      });

      if (_vocabList.isNotEmpty) {
        _trackCurrentWord();
        StreakService().updateStreak(context);
      }
    }
  }

  // LOAD TỪ TIẾP THEO (ON-DEMAND)
  Future<void> _loadNextWord() async {
    if (_isLoadingNext) return;

    setState(() => _isLoadingNext = true);

    // Tính page dựa trên số từ đã load
    // Page 1: từ 1-2, Page 2: từ 3, Page 3: từ 4...
    final nextPage = _vocabList.length + 1; // Vì page 1 có 2 từ rồi
    
    final result = await fetchVocabulariesPaginated(
      topicId: widget.topicId,
      level: widget.level,
      page: nextPage,
      limit: 1,
      context: context,
    );

    if (mounted) {
      final newWords = result['data'] as List<Vocabulary>;
      
      if (newWords.isNotEmpty) {
        setState(() {
          _vocabList.add(newWords[0]);
          _isLoadingNext = false;
        });
      } else {
        setState(() => _isLoadingNext = false);
      }
    }
  }

  // PREFETCH: Load trước từ tiếp theo (không cần setState)
  Future<void> _prefetchNextWord() async {
    // Chỉ prefetch nếu:
    // 1. Chưa đang load
    // 2. Chưa có từ tiếp theo trong list
    // 3. Còn từ để load
    if (_isLoadingNext || _vocabList.length >= _totalVocabs) return;

    final nextPage = _vocabList.length + 1;
    
    final result = await fetchVocabulariesPaginated(
      topicId: widget.topicId,
      level: widget.level,
      page: nextPage,
      limit: 1,
      context: context,
    );

    if (mounted) {
      final newWords = result['data'] as List<Vocabulary>;
      
      if (newWords.isNotEmpty) {
        setState(() {
          _vocabList.add(newWords[0]);
        });
        print("📚 Prefetched word ${_vocabList.length}");
      }
    }
  }
  Future<void> _handleAddToDictionary(String vocabularyId, String word) async {
    final success = await addVocabularyToDictionary(vocabularyId, context);

    if (mounted) {
      // Hiển thị thông báo (SnackBar)
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Ẩn thông báo cũ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? "✅ Đã thêm '$word' vào từ điển của bạn."
                : "❌ Lỗi: Không thể thêm từ vựng. Vui lòng thử lại.",
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // HÀM MỚI: Fetch Vocabularies với Pagination (cho On-Demand Loading)
  Future<Map<String, dynamic>> fetchVocabulariesPaginated({
    required String topicId,
    required String level,
    required int page,
    required int limit,
    BuildContext? context,
  }) async {
    final url = Uri.parse('$urlAPI/api/vocab?topic=$topicId&level=$level&page=$page&limit=$limit');
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
          return {'total': 0, 'page': page, 'limit': limit, 'data': []};
        }
      }

      if (res.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(res.body);

        List<dynamic> listData = jsonResponse['data'] ?? [];
        final List<Vocabulary> vocabs = listData.map((item) => Vocabulary.fromJson(item)).toList();

        print("📚 Loaded ${vocabs.length} vocabulary (page $page)");

        return {
          'total': jsonResponse['total'] ?? 0,
          'page': jsonResponse['page'] ?? page,
          'limit': jsonResponse['limit'] ?? limit,
          'data': vocabs,
        };
      } else {
        print("❌ Lỗi lấy vocab: ${res.statusCode} - ${res.body}");
        return {'total': 0, 'page': page, 'limit': limit, 'data': []};
      }
    } catch (e) {
      print("❌ Exception fetchVocabularies: $e");
      return {'total': 0, 'page': page, 'limit': limit, 'data': []};
    }
  }

  void _trackCurrentWord() {
    if (_vocabList.isNotEmpty) {
      final currentVocabId = _vocabList[_currentIndex].id;

      markVocabAsViewed(currentVocabId, context); // THÊM CONTEXT
    }
  }

  Future<void> _playAudio(String url) async {
    if (url.isEmpty) return;

    try {
      await _audioPlayer.stop();

      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      print("Lỗi phát âm thanh: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không thể phát âm thanh: Lỗi kết nối")),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    if (widget.onProgressUpdated != null) {
      widget.onProgressUpdated!();
    }
    super.dispose();
  }

  void _nextCard() {
    // Nếu đã có từ tiếp theo trong list
    if (_currentIndex < _vocabList.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _trackCurrentWord();
      
      // PREFETCH: Load trước từ tiếp theo (nếu chưa có)
      if (_currentIndex == _vocabList.length - 1 && _vocabList.length < _totalVocabs) {
        _prefetchNextWord();
      }
    }
    // Nếu chưa load hết tất cả từ vựng (case này không nên xảy ra nếu prefetch hoạt động tốt)
    else if (_vocabList.length < _totalVocabs) {
      // Hiển thị thông báo đang load (fallback)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đang tải từ tiếp theo..."), duration: Duration(seconds: 1)),
      );
    }
    // Đã học hết
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chúc mừng! Bạn đã học hết từ vựng chủ đề này.")),
      );

      Provider.of<UserProgressProvider>(context, listen: false)
          .fetchProgress(context);
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _trackCurrentWord(); // <--- Gọi API khi quay lại (tùy chọn)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5D3),
      appBar: AppBar(
        title: Text(widget.topicName), // Tên Topic
        backgroundColor: const Color(0xFFFFE474),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF5D4037)),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: const TextStyle(
          color: Color(0xFF5D4037),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vocabList.isEmpty
          ? const Center(child: Text("Chưa có từ vựng nào cho chủ đề này."))
          : _isLoadingNext
          ? const Center(child: CircularProgressIndicator()) // Loading từ tiếp theo
          : _buildCardContent(),
    );
  }

  Widget _buildCardContent() {
    final vocab = _vocabList[_currentIndex]; // Lấy dữ liệu động tại index hiện tại

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 1. Hình ảnh từ API
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        vocab.imageUrl,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            height: 220,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported)
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                              height: 220,
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator())
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      vocab.word,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3B6F),
                      ),
                    ),
                    const SizedBox(height: 5),

                    Text(
                      '(${vocab.type})',
                      style: const TextStyle(fontSize: 16, color: Color(0xFF757575)),
                    ),
                    const SizedBox(height: 5),

                    Text(
                      vocab.pronunciation,
                      style: TextStyle(fontSize: 18, color: Colors.blueGrey[400]),
                    ),
                    const SizedBox(height: 10),
                    // 5. Meaning (Nghĩa)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        vocab.meaning,
                        textAlign: TextAlign.center, // Căn giữa text
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _previousCard,
                            icon: Icon(Icons.arrow_back_ios,
                                color: _currentIndex > 0 ? Colors.grey : Colors.grey[300]
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _playAudio(vocab.audioUrl),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1B3B6F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.volume_up, color: Colors.white, size: 30),
                            ),
                          ),
                          IconButton(
                            onPressed: _nextCard,
                            icon: Icon(Icons.arrow_forward_ios,
                                color: _currentIndex < _vocabList.length - 1 ? Colors.grey : Colors.grey[300]
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.format_quote, color: Colors.grey, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              vocab.example,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),

          // Hiển thị số trang: 1/10 (dựa trên tổng số từ vựng)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              "${_currentIndex + 1} / $_totalVocabs",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}