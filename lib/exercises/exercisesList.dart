import 'package:flutter/material.dart';
import '../controller/exercisesController.dart';
import '../model/exercises.dart';
import '../component/messDialog.dart';

class PageExercisesList extends StatefulWidget {
  final String topicRef;

  const PageExercisesList({super.key, required this.topicRef});

  @override
  State<PageExercisesList> createState() => _PageExercisesListState();
}

class _PageExercisesListState extends State<PageExercisesList>
    with SingleTickerProviderStateMixin {

  final ExerciseController controller = ExerciseController();

  late Future<void> _futureLoad;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? selectedOption;
  TextEditingController answerController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _futureLoad = controller.fetchExercisesByTopicRef(widget.topicRef);

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
          widget.topicRef,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFFFF176),
        elevation: 0,
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

          if (item.type == "fill_in_blank") {
            if (controller.userAnswers.containsKey(item.id)) {
              answerController.text = controller.userAnswers[item.id]!;
            } else {
              answerController.text = "";
            }
          }

          return Column(
            children: [
              // Progress bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  widthFactor: (controller.currentIndex + 1) / controller.exercises.length,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF176), Color(0xFFFFD54F)],
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
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      borderRadius: BorderRadius.circular(40),
                                      onTap: () {
                                        controller.speakExercises(item.audioUrl);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.orange.withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            )
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.volume_up_rounded,
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
                                            ? const Color(0xFFFFD54F)
                                            : Colors.grey[300]!,
                                        width: 2,
                                      ),
                                      color: isSelected
                                          ? const Color(0xFFFFF176).withOpacity(0.3)
                                          : Colors.white,
                                    ),
                                    child: RadioListTile(
                                      enabled: !answered,
                                      value: o.text,
                                      groupValue: isSelected ? o.text : selectedOption,
                                      onChanged: answered
                                          ? null
                                          : (value) {
                                        setState(() {
                                          selectedOption = value.toString();
                                        });
                                      },
                                      title: Text(o.text),
                                      activeColor: const Color(0xFFFFD54F),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                          // FILL-IN
                          if (item.type == "fill_in_blank")
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.skill != "listening")
                                  TextField(
                                    enabled: !controller.isAnswered(),
                                    controller: answerController,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      hintText: "Nhập đáp án...",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),

                                if (item.skill == "listening")
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Enter the answer you hear",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        enabled: !controller.isAnswered(),
                                        controller: answerController,
                                        textAlign: TextAlign.center,
                                        decoration: const InputDecoration(
                                          hintText: "Enter your answer...",
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),

                          const SizedBox(height: 30),

                          // Button check
                          if (!controller.isAnswered())
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () async {
                                  String answer = "";

                                  if (item.type == "multiple_choice") {
                                    if (selectedOption == null) {
                                      showErrorDialog(context, "Vui lòng chọn đáp án!");
                                      return;
                                    }
                                    answer = selectedOption!;
                                  }

                                  if (item.type == "fill_in_blank") {
                                    if (answerController.text.trim().isEmpty) {
                                      showErrorDialog(context, "Bạn chưa nhập đáp án!");
                                      return;
                                    }
                                    answer = answerController.text.trim();
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

              // Navigation
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // PREVIOUS (KHÔNG CHO QUAY LẠI)
                    Opacity(
                      opacity: 0.4,
                      child: IconButton(
                        onPressed: null,
                        icon: const Icon(Icons.arrow_back_ios_new),
                      ),
                    ),

                    // NEXT
                    IconButton(
                      onPressed: controller.isAnswered()
                          ? () {
                        animateNext(() {
                          setState(() {
                            selectedOption = null;
                            answerController.clear();
                          });
                        });
                      }
                          : null,
                      icon: Icon(Icons.arrow_forward_ios,
                          color: controller.isAnswered()
                              ? Colors.black
                              : Colors.grey),
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
