import 'package:beelingual/app_UI/vocabulary_UI/level_Vocab.dart';
import 'package:beelingual/app_UI/vocabulary_UI/list_Vocab.dart';
import 'package:beelingual/component/progressProvider.dart';
import 'package:beelingual/connect_api/api_connect.dart';
import 'package:beelingual/model/model_Topic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Import file chứa Topic model và hàm fetchTopics của bạn ở đây

class AppColors {
  static const Color background = Color(0xFFFFFDE7);
  static const Color cardBackground = Color(0xFFFFF9C4);
  static const Color cardSelected = Color(0xFFFCE79A);
  static const Color iconActive = Color(0xFFEBC934);
  static const Color textDark = Color(0xFF5D4037);

  static const Color textLight = Color(0xFFA68B7B);
  static const Color buttonBackground = Color(0xFFFDF1C8);
  static const Color progressBarTrack = Color(0xFFE0B769);
  static const Color progressBarFill = Color(0xFF5D4037);
}

class LearningTopicsScreen extends StatefulWidget {
  const LearningTopicsScreen({super.key});

  @override
  State<LearningTopicsScreen> createState() => _LearningTopicsScreenState();
}

class _LearningTopicsScreenState extends State<LearningTopicsScreen> {
  // PAGINATION STATE
  List<Topic> _topics = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _totalTopics = 0;

  // SCROLL CONTROLLER
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Load progress và topics đầu tiên
    Future.delayed(Duration.zero, () {
      if (mounted) {
        Provider.of<UserProgressProvider>(context, listen: false).fetchProgress(context);
        _loadInitialTopics();
      }
    });

    // Thêm scroll listener để detect khi scroll gần cuối
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // SCROLL LISTENER: Trigger load thêm khi scroll đến 80% cuối danh sách
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreTopics();
    }
  }

  // LOAD 6 TOPICS ĐẦU TIÊN
  Future<void> _loadInitialTopics() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _topics.clear();
    });

    try {
      final result = await fetchTopicsPaginated(
        page: 1,
        limit: 6,
        context: context,
      );

      if (mounted) {
        setState(() {
          _topics = List<Topic>.from(result['data']);
          _totalTopics = result['total'] ?? 0;
          _hasMore = _topics.length < _totalTopics;
          _currentPage = 2; // Trang tiếp theo sẽ là 2
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading initial topics: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // LOAD THÊM 2 TOPICS MỖI LẦN SCROLL
  Future<void> _loadMoreTopics() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await fetchTopicsPaginated(
        page: _currentPage,
        limit: 2,
        context: context,
      );

      if (mounted) {
        final newTopics = List<Topic>.from(result['data']);
        
        setState(() {
          _topics.addAll(newTopics);
          _hasMore = _topics.length < _totalTopics;
          _currentPage++;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print("Error loading more topics: $e");
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  // PULL TO REFRESH: Reset về trang đầu
  Future<void> _refreshData() async {
    await Provider.of<UserProgressProvider>(context, listen: false).fetchProgress(context);
    await _loadInitialTopics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chủ đề từ vựng'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFE474),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildHeader(),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _topics.isEmpty
                        ? const Center(child: Text("Không có chủ đề nào"))
                        : GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 20.0,
                              mainAxisSpacing: 20.0,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: _topics.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Hiển thị loading indicator ở cuối danh sách
                              if (index == _topics.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              return TopicCard(topic: _topics[index]);
                            },
                          ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final progressProvider = Provider.of<UserProgressProvider>(context);

    // Lấy số liệu
    final percentage = progressProvider.topicProgressBarPercentage;
    final isLoading = progressProvider.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thanh Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Color(0xFF5D4037), // Nền trắng
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEBC934)), // Vàng đậm
            minHeight: 20.0,
          ),
        ),
        const SizedBox(height: 10.0),

        // Dòng Text thông tin
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bên trái: Hiển thị chữ "Tiến độ chung" hoặc "Lộ trình"
            const Text(
                'Lộ trình học tập',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 16)
            ),

            // Bên phải: Hiển thị %
            Text(
                isLoading ? '...%' : '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: AppColors.textDark)
            ),
          ],
        ),
      ],
    );
  }
}

// CẬP NHẬT TOPIC CARD ĐỂ HIỂN THỊ ẢNH URL
class TopicCard extends StatelessWidget {
  final Topic topic;

  const TopicCard({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (context) => LevelPage(topicId: topic.id, topicName: topic.title, topic: topic,)),
            );
          },
          borderRadius: BorderRadius.circular(20.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. ẢNH TOPIC
                Expanded(
                  flex: 3,
                  child: topic.imageUrl.isNotEmpty
                      ? Image.network(
                    topic.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
                    },
                  )
                      : const Icon(Icons.image, size: 50, color: AppColors.textDark),
                ),
                const SizedBox(height: 8.0),

                // 2. TÊN TOPIC
                Expanded(
                  flex: 1,
                  child: Text(
                    topic.title,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 3. THANH TIẾN ĐỘ (Thay cho pts và status cũ)
                Column(
                  children: [
                    // Dòng chữ ví dụ: "5/20 từ"
                    Text(
                      '${topic.learnedWords}/${topic.totalWords} từ',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6.0),

                    // Thanh Progress Bar nhỏ
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5.0),
                      child: LinearProgressIndicator(
                        value: topic.progress / 100, // Chuyển 50 thành 0.5
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          // Nếu 100% thì màu xanh lá, chưa xong thì màu vàng cam
                            topic.progress >= 100 ? Colors.green : AppColors.progressBarFill
                        ),
                        minHeight: 8.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),

                    // Số phần trăm
                    Text(
                      '${topic.progress}%',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}