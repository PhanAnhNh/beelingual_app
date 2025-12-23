import 'package:beelingual/app_UI/account/logIn.dart';
import 'package:beelingual/app_UI/home_UI/bottom_navigation.dart';
import 'package:beelingual/component/profileProvider.dart';
import 'package:beelingual/component/progressProvider.dart';
import 'package:beelingual/component/vocabularyProvider.dart';
import 'package:beelingual/connect_api/api_connect.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          create: (context) => UserProfileProvider(context),
        ),
        ChangeNotifierProvider<UserProgressProvider>(
          create: (context) => UserProgressProvider(context),
        ),
      ],
      child: MaterialApp( // Bỏ const ở đây vì home sẽ thay đổi động
        debugShowCheckedModeBanner: false,
        title: "Beelingual",

        // --- SỬA ĐỔI PHẦN NÀY ---
        // Thay vì gọi trực tiếp home_navigation(), ta kiểm tra Token trước
        home: FutureBuilder<bool>(
          future: SessionManager().isLoggedIn(), // Gọi hàm kiểm tra có token không
          builder: (context, snapshot) {
            // 1. Đang kiểm tra -> Hiện vòng xoay loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.amber),
                ),
              );
            }

            // 2. Đã có kết quả
            if (snapshot.hasData && snapshot.data == true) {
              // Nếu đã đăng nhập -> Vào trang chủ (có BottomBar)
              return const home_navigation();
            } else {
              // Nếu chưa đăng nhập -> Vào trang Login (Full màn hình, không có BottomBar)
              return const PageLogIn(); // Đảm bảo class Login của bạn tên là PageLogIn như trong code Logout
            }
          },
        ),
        // ------------------------
      ),
    );
  }
}