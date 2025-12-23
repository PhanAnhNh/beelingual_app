import 'package:beelingual/app_UI/grammar_UI/exercisesGrmList.dart';
import 'package:beelingual/connect_api/api_Streak.dart';
import 'package:beelingual/controller/grammar.dart';
import 'package:beelingual/model/model_grammar.dart';
import 'package:flutter/material.dart';

class PageGrammar extends StatefulWidget {
  final String title;
  final String categoryId;

  const PageGrammar({
    super.key,
    required this.title,
    required this.categoryId,
  });

  @override
  State<PageGrammar> createState() => _PageGrammarState();
}

class _PageGrammarState extends State<PageGrammar> {
  late Future<List<Grammar>> _futureGrammar;

  final List<List<Color>> cardGradients = [
    [Color(0xFFFFD194), Color(0xFFFF8A65)],
    [Color(0xFFB6F492), Color(0xFF338B93)],
    [Color(0xFFD4BFFF), Color(0xFF9B6DFF)],
    [Color(0xFFA1FFCE), Color(0xFF3EB489)],
  ];

  @override
  void initState() {
    super.initState();
    _futureGrammar = fetchAllGrammarByCategory(widget.categoryId);

    _futureGrammar.then((data) {
      // Kiểm tra nếu màn hình còn hiển thị và có dữ liệu thì mới update streak
      if (mounted && data.isNotEmpty) {
        StreakService().updateStreak(context).then((_) {
          // Có thể print log nếu muốn kiểm tra
          // print("Đã cập nhật streak ngữ pháp");
        });
      }
    }).catchError((error) {
      // Xử lý lỗi nếu cần, hoặc bỏ qua để không ảnh hưởng luồng chính
      print("Lỗi khi tải Grammar để tính streak: $error");
    });
    // ------------------------------------
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFE474),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF5D4037),
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Grammar>>(
        future: _futureGrammar,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _emptyState();
          }

          final tenseList = snapshot.data!;
          tenseList.sort((a, b) => (a.createdAt ?? DateTime.now())
              .compareTo(b.createdAt ?? DateTime.now()));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: tenseList.length,
            itemBuilder: (context, index) {
              final grammar = tenseList[index];
              final gradient =
              cardGradients[index % cardGradients.length];

              return _grammarCard(grammar, index, gradient);
            },
          );
        },
      ),
    );
  }

  Widget _grammarCard(Grammar grammar, int index, List<Color> gradient) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PageGrammarDetail(grammar: grammar),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: gradient),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            /// 🔢 Index
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
            const SizedBox(width: 16),

            /// 📘 Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grammar.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Level: ${grammar.level}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.menu_book, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No grammar available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
class PageGrammarDetail extends StatelessWidget {
  final Grammar grammar;
  const PageGrammarDetail({super.key, required this.grammar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE474),
        elevation: 0,
        title: Text(
          grammar.title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF5D4037),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _section('Cấu trúc', grammar.structure, Icons.account_tree),
            _section('Cách dùng', grammar.content, Icons.menu_book),
            _section('Ví dụ', grammar.example, Icons.lightbulb_outline),

            const SizedBox(height: 30),

            /// 🚀 CTA
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_note, size: 26),
                label: const Text(
                  'Luyện tập ngay',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 6,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PageExercisesGrmList(
                        grammarId: grammar.id,
                        grammarTitle: grammar.title,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFFA000)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
        ],
      ),
    );
  }
}
