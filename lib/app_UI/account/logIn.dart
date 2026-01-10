import 'package:beelingual_app/app_UI/account/signUp.dart';
import 'package:beelingual_app/app_UI/home_UI/bottom_navigation.dart';
import 'package:beelingual_app/component/messDialog.dart';
import 'package:beelingual_app/connect_api/api_connect.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../component/profileProvider.dart';
import '../../component/progressProvider.dart';
import '../../component/vocabularyProvider.dart';

class PageLogIn extends StatefulWidget {
  const PageLogIn({super.key});

  @override
  State<PageLogIn> createState() => _PageLogInState();
}

class _PageLogInState extends State<PageLogIn> {
  bool seePass = true;
  bool isLoading = false;
  final TextEditingController username = TextEditingController();
  final TextEditingController pass = TextEditingController();
  final session = SessionManager();

  @override
  void dispose() {
    username.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
          children:[
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFE082),
                    Color(0xFFFFFDE7),
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 25,
                              color: Colors.black26,
                              offset: Offset(0, 10),
                            )
                          ],
                        ),
                        child: Image.asset(
                          "assets/Images/logoBee.png",
                          width: 120,
                          height: 120,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// TEXT
                      const Text(
                        "Welcome to Beelingual",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF5D4037),
                        ),
                      ),

                      const SizedBox(height: 30),

                      _inputField(
                        controller: username,
                        hint: "Username",
                        icon: Icons.person,
                      ),

                      const SizedBox(height: 16),

                      _inputField(
                        controller: pass,
                        hint: "Password",
                        icon: Icons.lock,
                        obscure: seePass,
                        suffix: IconButton(
                          icon: Icon(
                            seePass ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => seePass = !seePass);
                          },
                        ),
                      ),

                      const SizedBox(height: 26),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _handleLogin,
                          icon: isLoading
                              ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                              : const Icon(Icons.login),
                          label: Text(
                            isLoading ? "Logging in..." : "Log in",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PageSignUp()),
                            );
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text(
                            "Sign up",
                            style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFA000),
                            side: const BorderSide(color: Color(0xFFFFC107)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Forgot password?",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ]
      ),
    );
  }

  Future<void> _handleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();

    String usernameText = username.text.trim();
    String passwordText = pass.text.trim();

    if (usernameText.isEmpty || passwordText.isEmpty) {
      showErrorDialog(context, "Thông báo","Vui lòng nhập đầy đủ thông tin");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final token = await session.login(username: usernameText, password: passwordText);

      if (!mounted) return;

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', token['accessToken']!);
        await prefs.setString('refreshToken', token['refreshToken']!);

        if (!mounted) return;

        context.read<UserProfileProvider>().clear();
        context.read<UserVocabularyProvider>().clear();
        context.read<UserProgressProvider>().clear();
        await context.read<UserProfileProvider>().fetchProfile(context);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const home_navigation()),
        );

      } else {
        if (!mounted) return;
        showErrorDialog(context, "Thông báo","Username hoặc Password không đúng");
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, "Thông báo","Đã có lỗi xảy ra: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.amber),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}