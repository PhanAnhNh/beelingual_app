import 'package:beelingual/app_UI/vocabulary_UI/levelVocab.dart';
import 'package:beelingual/component/progressProvider.dart';
import 'package:beelingual/connect_api/api_connect.dart';
import 'package:beelingual/model/model_Topic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppColors {
  static const Color background = Color(0xFFFFFDE7);
  static const Color cardBackground = Color(0xFFFFF9C4);
  static const Color cardSelected = Color(0xFFFCE79A);
  static const Color iconActive = Color(0xFFEBC934);
  static const Color textDark = Color(0xFF5D4037);
  static const Color textLight = Color(0xFFA68B7B);
  static const Color progressBarFill = Color(0xFF5D4037);
}

class LearningTopicsScreen extends StatefulWidget {
  const LearningTopicsScreen({super.key});

  @override
  State<LearningTopicsScreen> createState() => _LearningTopicsScreenState();
}

class _LearningTopicsScreenState extends State<LearningTopicsScreen> {
  final ScrollController _scrollController = ScrollController();

  List<Topic> _topics = [];
  int _currentPage = 1;
  int _totalTopics = 0;

  bool _isLoading = false;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await Provider.of<UserProgressProvider>(context, listen: false)
          .fetchProgress(context);
      await _loadInitialTopics();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasMore) return;

    final threshold =
        _scrollController.position.maxScrollExtent - 200;

    if (_scrollController.position.pixels >= threshold) {
      _loadMoreTopics();
    }
  }

  // LOAD PAGE 1
  Future<void> _loadInitialTopics() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _topics.clear();
      _hasMore = true;
    });

    try {
      final result = await fetchTopicsPaginated(
        page: 1,
        limit: 6,
        context: context,
      );

      final List<Topic> fetched = List<Topic>.from(result['data']);

      if (!mounted) return;

      setState(() {
        _topics = fetched;
        _totalTopics = result['total'] ?? 0;
        _hasMore = _topics.length < _totalTopics;
        _currentPage = 2;
      });
    } catch (e) {
      debugPrint("Load initial error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // LOAD MORE
  Future<void> _loadMoreTopics() async {
    if (_isFetchingMore || !_hasMore || _isLoading) return;

    _isFetchingMore = true;

    try {
      final result = await fetchTopicsPaginated(
        page: _currentPage,
        limit: 2,
        context: context,
      );

      final List<Topic> newTopics = List<Topic>.from(result['data']);

      if (!mounted) return;

      setState(() {
        _topics.addAll(
          newTopics.where(
                (t) => !_topics.any((e) => e.id == t.id),
          ),
        );
        _hasMore = _topics.length < _totalTopics;
        _currentPage++;
      });
    } catch (e) {
      debugPrint("Load more error: $e");
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<void> _refreshData() async {
    _isFetchingMore = false;
    _currentPage = 1;
    _hasMore = true;

    await Provider.of<UserProgressProvider>(context, listen: false)
        .fetchProgress(context);
    await _loadInitialTopics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vocabulary Topic',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                padding: const EdgeInsets.all(20),
                child: _buildHeader(),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _topics.isEmpty
                    ? const Center(child: Text("Không có chủ đề nào"))
                    : GridView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    100, // 👈 khoảng trắng bên dưới
                  ),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.8,
                  ),
                  itemCount:
                  _topics.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _topics.length) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return TopicCard(topic: _topics[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final provider = Provider.of<UserProgressProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: provider.topicProgressBarPercentage / 100,
            backgroundColor: AppColors.progressBarFill,
            valueColor:
            const AlwaysStoppedAnimation(Color(0xFFEBC934)),
            minHeight: 20,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lộ trình học tập',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                fontSize: 16,
              ),
            ),
            Text(
              provider.isLoading
                  ? '...%'
                  : '${provider.topicProgressBarPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TopicCard extends StatelessWidget {
  final Topic topic;

  const TopicCard({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LevelPage(
                  topicId: topic.id,
                  topicName: topic.title,
                  topic: topic,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: topic.imageUrl.isNotEmpty
                      ? Image.network(topic.imageUrl)
                      : const Icon(Icons.image, size: 50),
                ),
                const SizedBox(height: 8),
                Text(
                  topic.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${topic.learnedWords}/${topic.totalWords} từ',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: topic.progress / 100,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation(
                    topic.progress >= 100
                        ? Colors.green
                        : AppColors.progressBarFill,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${topic.progress}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
