import 'package:beelingual/app_UI/grammar_UI/detailGrammar.dart';
import 'package:beelingual/controller/grammar.dart';
import 'package:beelingual/model/model_grammar.dart';
import 'package:flutter/material.dart';

class PageGrammarList extends StatefulWidget {
  const PageGrammarList({super.key});

  @override
  State<PageGrammarList> createState() => _PageGrammarListState();
}

class _PageGrammarListState extends State<PageGrammarList> {
  late Future<List<Category>> _futureCategory;

  @override
  void initState() {
    super.initState();
    _futureCategory = fetchAllCategory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Grammar"),
        backgroundColor: Color(0xFFFFF176),
        elevation: 0,
      ),
      backgroundColor: Color(0xFFFFF9C4),
      body: FutureBuilder<List<Category>>(
        future: _futureCategory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No categories found'));
          }

          final categories = snapshot.data!;
          // Sắp xếp theo thời gian tạo (mới nhất lên đầu)
          categories.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return a.createdAt!.compareTo(b.createdAt!);
          });
          final List<Color> colors = [
            Colors.orange,
            Colors.blue,
            Colors.green,
            Colors.purple,
            Colors.deepOrange,
            Colors.amber,
          ];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final item = categories[index];
              final color = colors[index % colors.length];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Text(
                      item.icon.isNotEmpty ? item.icon : item.name[0],
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PageGrammar(
                          title: item.name,
                          categoryId: item.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

