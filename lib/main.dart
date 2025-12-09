import 'package:beelingual/grammar/gammarList.dart';
import 'package:beelingual/home.dart';
import 'package:flutter/material.dart';
import 'controller/accountController.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Listener(
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        ),
        debugShowCheckedModeBanner: false,
        home: PageHome(),
      ),
    );
  }
}
