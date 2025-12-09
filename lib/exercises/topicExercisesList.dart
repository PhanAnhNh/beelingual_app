import 'package:flutter/material.dart';
import 'package:beelingual/model/exercises.dart';
import '../controller/exercisesController.dart';
import '../controller/topicController.dart';
import '../model/topic.dart';
import 'exercisesList.dart'; // nơi bạn để fetchAllExercises

class PageTopicExercisesList extends StatefulWidget {
  const PageTopicExercisesList({super.key});

  @override
  State<PageTopicExercisesList> createState() => _PageTopicExercisesListState();
}

class _PageTopicExercisesListState extends State<PageTopicExercisesList> {
  late Future<List<Topic>> _futureTopic;

  @override
  void initState() {
    super.initState();
    _futureTopic = fetchAllTopic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Exercises'),
        backgroundColor: const Color(0xFFFFF176),
      ),
      body: FutureBuilder<List<Topic>>(
        future: _futureTopic,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          final exercises = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
              itemBuilder: (context, index) {
                final item = exercises[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>PageExercisesList(
                          topicRef: item.name,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, color: Colors.white),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Level: ${item.level}',
                                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
          );
        },
      ),
    );
  }
}
