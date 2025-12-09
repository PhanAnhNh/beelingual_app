import 'package:flutter/material.dart';
import '../model/exercises.dart';
import '../controller/exercisesController.dart'; // nơi chứa fetchAllExercisesByTopicRef

class PageExercisesList extends StatefulWidget {
  final String topicRef;

  const PageExercisesList({super.key, required this.topicRef});

  @override
  State<PageExercisesList> createState() => _PageExercisesListState();
}

class _PageExercisesListState extends State<PageExercisesList> {
  late Future<List<Exercises>> _futureExercises;

  int currentIndex = 0;
  String? selectedOption;
  TextEditingController answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureExercises = fetchAllExercisesByTopicRef(widget.topicRef);
  }

  void nextQuestion(int total) {
    if (currentIndex < total - 1) {
      setState(() {
        currentIndex++;
        selectedOption = null;
        answerController.clear();
      });
    }
  }

  void prevQuestion() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        selectedOption = null;
        answerController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicRef),
        backgroundColor: const Color(0xFFFFF176),
      ),
      body: FutureBuilder<List<Exercises>>(
        future: _futureExercises,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có bài tập'));
          }

          final exercises = snapshot.data!;
          final item = exercises[currentIndex];

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.questionText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        if (item.type == "multiple_choice")
                          Column(
                            children: item.options.map((option) {
                              return RadioListTile(
                                title: Text(option.text),
                                value: option.text,
                                groupValue: selectedOption,
                                onChanged: (value) {
                                  setState(() {
                                    selectedOption = value.toString();
                                  });
                                },
                              );
                            }).toList(),
                          ),

                        if (item.type == "fill_in_blank")
                          SizedBox(
                            width: double.infinity,
                            child: TextField(
                              controller: answerController,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Nhập đáp án...",
                              ),
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightGreenAccent,   // 🔵 màu xanh
                              foregroundColor: Colors.white,  // màu chữ
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Check'),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: currentIndex > 0
                          ? () => prevQuestion()
                          : null,
                      icon: const Icon(Icons.arrow_left, size: 40),
                    ),
                    const SizedBox(width: 60),
                    Text(
                      "Câu ${currentIndex + 1}/${exercises.length}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 60),
                    IconButton(
                      onPressed: currentIndex < exercises.length - 1
                          ? () => nextQuestion(exercises.length)
                          : null,
                      icon: const Icon(Icons.arrow_right, size: 40),
                    ),
                  ],
                ),
              ),


            ],
          );
        },
      ),
    );
  }
}

