import 'package:flutter/material.dart';
import "package:provider/provider.dart";
import 'controller/translateController.dart';

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
      appBar: AppBar(
        title: const Text('Translate'),
        backgroundColor: Color(0xFFFFF176),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: controller.fromLang,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "From",
                    ),
                    items: controller.languages
                        .map((lang) =>
                        DropdownMenuItem(value: lang, child: Text(lang)))
                        .toList(),
                    onChanged: (value) {
                      controller.fromLang = value!;
                      controller.translate();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.swap_horiz, size: 32),
                  onPressed: controller.swapLanguages,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: controller.toLang,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "To",
                    ),
                    items: controller.languages
                        .map((lang) =>
                        DropdownMenuItem(value: lang, child: Text(lang)))
                        .toList(),
                    onChanged: (value) {
                      controller.toLang = value!;
                      controller.translate();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller.inputController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Enter text to translate...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => controller.translate(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 150,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 150,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        controller.result.isEmpty
                            ? "Translation result..."
                            : controller.result,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      children: [
                        GestureDetector(
                        onTap: () {
                          controller.pause(); // <-- gọi method pause trong TranslateController
                          print("Pause translation audio");
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.stop,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            controller.speakResult();
                            print("Play translation audio");
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.volume_up,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
