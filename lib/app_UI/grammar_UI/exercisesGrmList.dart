import 'package:beelingual/component/messDialog.dart';
import 'package:beelingual/controller/exeGrm_Controller.dart';
import 'package:beelingual/model/exercisesGrm.dart';
import 'package:flutter/material.dart';

class PageExercisesGrmList extends StatefulWidget {
  final String grammarId;
  final String grammarTitle;

  const PageExercisesGrmList({
    super.key,
    required this.grammarId,
    required this.grammarTitle,
  });

  @override
  State<PageExercisesGrmList> createState() => _PageExercisesListState();
}

class _PageExercisesListState extends State<PageExercisesGrmList>
    with SingleTickerProviderStateMixin {

  final ExerciseGrmController controller = ExerciseGrmController();

  late Future<void> _futureLoad;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? selectedOption;
  TextEditingController answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureLoad = controller.fetchExercisesByGrammarId(widget.grammarId);

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
          widget.grammarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFFFF176),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
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

          if (controller.exercisesGrm.isEmpty) {
            return const Center(child: Text("Không có bài tập cho chủ đề này"));
          }

          final ExercisesGrm item = controller.exercisesGrm[controller.currentIndex];

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
                  widthFactor: (controller.currentIndex + 1) / controller.exercisesGrm.length,
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
                "Câu ${controller.currentIndex + 1}/${controller.exercisesGrm.length}",
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

                          // Question
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              item.question,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // MULTIPLE CHOICE
                          if (item.options.isNotEmpty)
                            Column(
                              children: item.options.map((optionText) {
                                final answered = controller.isAnswered();
                                final userChoice = controller.userAnswers[item.id];

                                final isSelected = answered
                                    ? (userChoice == optionText)
                                    : (selectedOption == optionText);

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
                                    child: RadioListTile<String>(
                                      enabled: !answered,
                                      value: optionText,
                                      groupValue: selectedOption,
                                      onChanged: answered
                                          ? null
                                          : (value) {
                                        setState(() {
                                          selectedOption = value;
                                        });
                                      },
                                      title: Text(optionText),
                                      activeColor: const Color(0xFFFFD54F),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                          // FILL-IN
                          if (item.options.isEmpty)
                            TextField(
                              enabled: !controller.isAnswered(),
                              controller: answerController,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                hintText: "Nhập đáp án...",
                                border: OutlineInputBorder(),
                              ),
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
                                  String answer;

                                  if (item.options.isNotEmpty) {
                                    if (selectedOption == null) {
                                      showErrorDialog(context, "Thông báo","Vui lòng chọn đáp án!");
                                      return;
                                    }
                                    answer = selectedOption!;
                                  } else {
                                    if (answerController.text.trim().isEmpty) {
                                      showErrorDialog(context, "Thông báo","Bạn chưa nhập đáp án!");
                                      return;
                                    }
                                    answer = answerController.text.trim();
                                  }

                                  await controller.answerQuestion(
                                    context: context,
                                    userAnswer: answer,
                                  );

                                  setState(() {
                                    selectedOption = null;
                                    answerController.clear();
                                  });
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
                            controller.goToNextQuestion(context);
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
