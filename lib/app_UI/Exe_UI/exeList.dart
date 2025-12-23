import 'package:beelingual/component/messDialog.dart';
import 'package:beelingual/connect_api/api_Streak.dart';
import 'package:beelingual/controller/exercise_Controller.dart';
import 'package:beelingual/model/model_exercise.dart';
import 'package:flutter/material.dart';

class PageExercisesList extends StatefulWidget {
  final String topicId;
  final String name;

  const PageExercisesList({super.key, required this.topicId, required this.name});

  @override
  State<PageExercisesList> createState() => _PageExercisesListState();
}

class _PageExercisesListState extends State<PageExercisesList> with SingleTickerProviderStateMixin {
  final ExerciseController controller = ExerciseController();

  late Future<void> _futureLoad;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? selectedOption;
  TextEditingController answerController = TextEditingController();
  List<TextEditingController> clozeControllers = [];
  List<String> clozeAnswers = [];

  @override
  void initState() {
    super.initState();
    controller.onAudioStateChange = () {
      if (mounted) setState(() {});
    };
    _futureLoad = controller.fetchExercisesByTopicId(widget.topicId);
    _futureLoad.then((_) {
      // Kiểm tra: Nếu màn hình còn mở VÀ danh sách bài tập không rỗng
      if (mounted && controller.exercises.isNotEmpty) {
        StreakService().updateStreak(context).then((_) {
          // print("Đã cập nhật streak bài tập");
        });
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    answerController.dispose();
    super.dispose();
  }

  void animateNext(VoidCallback doChange) {
    _animationController.reverse().then((_) {
      doChange();
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          widget.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: const Color(0xFFFFF176),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87 // Màu đen cho giống Title
          ),
          onPressed: () {
            Navigator.pop(context); // Lệnh quay về trang trước
          },
        ),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder(
        future: _futureLoad,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFFFF176)),
              ),
            );
          }

          if (controller.exercises.isEmpty) {
            return const Center(child: Text("Không có bài tập"));
          }

          final Exercises item = controller.exercises[controller.currentIndex];

          // ===== INIT FILL IN =====
          if (item.type == "fill_in_blank") {
            answerController.text =
                controller.userAnswers[item.id] ?? "";
          }

          // ===== INIT CLOZE TEST =====
          if (item.type == "cloze_test") {
            clozeAnswers = item.correctAnswer.split("/");

            if (clozeControllers.length != clozeAnswers.length) {
              for (final c in clozeControllers) {
                c.dispose();
              }
              clozeControllers = List.generate(
                clozeAnswers.length,
                    (_) => TextEditingController(),
              );
            }

            if (controller.userAnswers.containsKey(item.id)) {
              final saved =
              controller.userAnswers[item.id]!.split("/");
              for (int i = 0; i < saved.length; i++) {
                clozeControllers[i].text = saved[i];
              }
            }
          }

          return Column(
            children: [
              // ===== PROGRESS =====
              Container(
                margin:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  widthFactor:
                  (controller.currentIndex + 1) / controller.exercises.length,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFF176),
                          Color(0xFFFFD54F)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              Text(
                "Question ${controller.currentIndex + 1}/${controller.exercises.length}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),

              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // ===== QUESTION =====
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.questionText,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                if (item.skill == "listening")
                                  Center(
                                    child: InkWell(
                                      borderRadius:
                                      BorderRadius.circular(40),
                                      onTap: () async {
                                        await controller.speakExercises(
                                            item.audioUrl);
                                      },
                                      child: Container(
                                        padding:
                                        const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.orange
                                              .withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          controller.isPlaying
                                              ? Icons.stop
                                              : Icons
                                              .volume_up_rounded,
                                          size: 32,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // ===== MULTIPLE CHOICE =====
                          if (item.type == "multiple_choice")
                            Column(
                              children: item.options.map((o) {
                                final answered = controller.isAnswered();
                                final userChoice = controller.userAnswers[item.id];
                                final isSelected = answered
                                    ? (userChoice == o.text)
                                    : (selectedOption == o.text);

                                return Opacity(
                                  opacity: answered ? 0.5 : 1,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(
                                            0xFFFFD54F)
                                            : Colors.grey[300]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: RadioListTile<String>(
                                      enabled: !answered,
                                      value: o.text,
                                      groupValue: selectedOption,
                                      onChanged: answered
                                          ? null
                                          : (v) {
                                        setState(() {
                                          selectedOption = v.toString();
                                        });
                                      },
                                      title: Text(o.text),
                                      activeColor: const Color(0xFFFFD54F),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                          // ===== FILL IN BLANK =====
                          if (item.type == "fill_in_blank")
                            TextField(
                              enabled: !controller.isAnswered(),
                              controller: answerController,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                hintText: "Enter your answer...",
                                border: OutlineInputBorder(),
                              ),
                            ),

                          // ===== CLOZE TEST =====
                          if (item.type == "cloze_test")
                            Column(
                              children: List.generate(
                                clozeControllers.length,
                                    (index) => Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 12),
                                  child: TextField(
                                    enabled:
                                    !controller.isAnswered(),
                                    controller:
                                    clozeControllers[index],
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      hintText:
                                      "Answer ${index + 1}",
                                      border:
                                      const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 30),

                          // ===== CHECK =====
                          if (!controller.isAnswered())
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFF4CAF50),
                                  shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () async {
                                  String answer = "";

                                  if (item.type ==
                                      "multiple_choice") {
                                    if (selectedOption == null) {
                                      showErrorDialog(context,
                                          "Thông báo","Vui lòng chọn đáp án!");
                                      return;
                                    }
                                    answer = selectedOption!;
                                  }

                                  if (item.type ==
                                      "fill_in_blank") {
                                    if (answerController.text
                                        .trim()
                                        .isEmpty) {
                                      showErrorDialog(context,
                                          "Thông báo","Bạn chưa nhập đáp án!");
                                      return;
                                    }
                                    answer = answerController.text
                                        .trim();
                                  }

                                  if (item.type ==
                                      "cloze_test") {
                                    for (final c
                                    in clozeControllers) {
                                      if (c.text
                                          .trim()
                                          .isEmpty) {
                                        showErrorDialog(context,
                                            "Thông báo","Bạn chưa nhập đủ đáp án!");
                                        return;
                                      }
                                    }
                                    answer = clozeControllers
                                        .map((c) =>
                                        c.text.trim())
                                        .join("/");
                                  }

                                  await controller.answerQuestion(
                                    context: context,
                                    userAnswer: answer,
                                  );

                                  setState(() {});
                                },
                                child: const Text(
                                  "Check Answer",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ===== NAV =====
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Opacity(
                      opacity: 0.4,
                      child: Icon(Icons.arrow_back_ios_new),
                    ),
                    IconButton(
                      icon: const Icon(
                          Icons.arrow_forward_ios),
                      onPressed: controller.isAnswered()
                          ? () {
                        animateNext(() {
                          setState(() {
                            selectedOption = null;
                            answerController.clear();
                            for (final c
                            in clozeControllers) {
                              c.clear();
                            }
                          });
                        });
                      }
                          : null,
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
