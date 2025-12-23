import 'package:beelingual/controller/translate_Controller.dart';
import 'package:flutter/material.dart';
import "package:provider/provider.dart";


class PageTranslate extends StatefulWidget {
  const PageTranslate({super.key});

  @override
  State<PageTranslate> createState() => _PageTranslateState();
}

class _PageTranslateState extends State<PageTranslate> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TranslateController(),
      child: const TranslatePageUI(),
    );
  }
}

class TranslatePageUI extends StatelessWidget {
  const TranslatePageUI({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TranslateController>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Translate',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFFFF176),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Language selector card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // From Language
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: controller.fromLang,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFF176),
                              width: 2,
                            ),
                          ),
                          labelText: "From",
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: controller.languages
                            .map((lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(
                            lang,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ))
                            .toList(),
                        onChanged: (value) {
                          controller.fromLang = value!;
                          controller.translate();
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4), // giảm padding
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF176).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.swap_horiz, size: 28),
                          color: Colors.black87,
                          onPressed: controller.swapLanguages,
                          padding: EdgeInsets.zero, // ✅ giảm padding
                          constraints: const BoxConstraints(), // ✅ tránh chiếm chỗ thừa
                        ),
                      ),
                    ),

                    // To Language
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true, // ✅ tránh overflow
                        value: controller.toLang,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFF176),
                              width: 2,
                            ),
                          ),
                          labelText: "To",
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: controller.languages
                            .map((lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(
                            lang,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ))
                            .toList(),
                        onChanged: (value) {
                          controller.toLang = value!;
                          controller.translate();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.translate,
                            color: Color(0xFFFFF176),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Text to translate',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const Spacer(),
                          // Pause button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.stop, size: 20),
                              color: Colors.grey[700],
                              onPressed: () {
                                controller.pauseInp();
                                print("Pause input audio");
                              },
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Speak button
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF176),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.volume_up, size: 20),
                              color: Colors.black87,
                              onPressed: () async {
                                controller.speakInput();
                                print("Play input audio");
                              },
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TextField(
                        controller: controller.inputController,
                        maxLines: 5,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "Enter text to translate...",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFF176),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onChanged: (_) => controller.translate(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Result card
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 180,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF66BB6A),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Translation result',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.stop, size: 20),
                                  color: Colors.grey[700],
                                  onPressed: () {
                                    controller.pauseOut();
                                    print("Pause translation audio");
                                  },
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF176),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.volume_up, size: 20),
                                  color: Colors.black87,
                                  onPressed: () {
                                    controller.speakResult();
                                    print("Play translation audio");
                                  },
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 120,
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            controller.result.isEmpty
                                ? "Translation will appear here..."
                                : controller.result,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: controller.result.isEmpty
                                  ? Colors.grey[400]
                                  : Colors.black87,
                            ),
                          ),
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
    );
  }
}