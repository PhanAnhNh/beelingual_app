import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_UI/account/logIn.dart';
import 'app_UI/home_UI/bottom_navigation.dart';
import 'component/profileProvider.dart';
import 'component/progressProvider.dart';
import 'component/vocabularyProvider.dart';
import 'connect_api/api_connect.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserVocabularyProvider>(
          create: (context) => UserVocabularyProvider(context),
        ),
        ChangeNotifierProvider<UserProfileProvider>(
          create: (context) => UserProfileProvider()..reloadProfile(context),
        ),
        ChangeNotifierProvider<UserProgressProvider>(
          create: (context) => UserProgressProvider(context),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Beelingual",
        home: FutureBuilder<bool>(
          future: SessionManager().isLoggedIn(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.amber),
                ),
              );
            }
            if (snapshot.hasData && snapshot.data == true) {
              return const home_navigation();
            } else {
              return const PageLogIn();
            }
          },
        ),
      ),
    );
  }
}