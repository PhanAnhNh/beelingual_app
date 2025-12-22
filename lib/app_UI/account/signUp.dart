import 'package:beelingual_app/app_UI/account/logIn.dart';
import 'package:beelingual_app/app_UI/account/termPage.dart';
import 'package:beelingual_app/component/messDialog.dart';
import 'package:beelingual_app/connect_api/api_connect.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class PageSignUp extends StatefulWidget {
  const PageSignUp({super.key});

  @override
  _PageSignUpState createState() => _PageSignUpState();
}

class _PageSignUpState extends State<PageSignUp> {
  bool seePass = true;
  bool seeConPass = true;
  bool agreeTerms = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController conPassController = TextEditingController();
  String role = 'student';
  final session = SessionManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF9C4),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                )
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: 10),
                Image.asset(
                  "assets/Images/user.png",
                  width: 100,
                  height: 100,
                ),
                SizedBox(height: 5),
                Center(
                  child: Text(
                    'Sign Up',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: fullnameController,
                  style: TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: "Fullname",
                    hintText: 'Trần Đăng Khoa',
                    labelStyle: TextStyle(fontSize: 15),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: usernameController,
                  style: TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: "Username",
                    hintText: 'KhoaTD',
                    labelStyle: TextStyle(fontSize: 15),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  style: TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: "Email",
                    hintText: 'beelingual@gmail.com',
                    labelStyle: TextStyle(fontSize: 15),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: passController,
                  obscureText: seePass,
                  style: TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(fontSize: 15),
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        seePass ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          seePass = !seePass;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: conPassController,
                  obscureText: seeConPass,
                  style: TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    labelStyle: TextStyle(fontSize: 15),
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        seeConPass ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          seeConPass = !seeConPass;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: agreeTerms,
                      onChanged: (value) {
                        setState(() {
                          agreeTerms = value!;
                        });
                      },
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'Tôi đồng ý với ',
                          style: TextStyle(color: Colors.black, fontSize: 15),
                          children: [
                            TextSpan(
                              text: 'Điều khoản sử dụng',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TermsPage(),
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    String user = usernameController.text.trim();
                    String name = fullnameController.text.trim();
                    String email = emailController.text.trim();
                    String pass = passController.text.trim();
                    String conPass = conPassController.text.trim();

                    if (!agreeTerms) {
                      showErrorDialog(context, "Bạn phải đồng ý với Điều khoản sử dụng.");
                      return;
                    }

                    if (user.isEmpty || name.isEmpty || email.isEmpty || pass.isEmpty || conPass.isEmpty) {
                      showErrorDialog(context, "Vui lòng nhập đầy đủ thông tin!");
                      return;
                    }

                    if (pass != conPass) {
                      showErrorDialog(context, "Mật khẩu không khớp!");
                      return;
                    }

                    final res = await session.signUp(
                      username: user,
                      email: email,
                      fullname: name,
                      password: pass,
                      role: role,
                    );

                    if (res == null) {
                      showErrorDialog(context, "Lỗi không xác định!");
                      return;
                    }

                    if (res["error"] == true) {
                      showErrorDialog(context, res["message"]);
                    } else {
                      await showSuccessDialog(context, "Đăng ký thành công!");
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PageLogIn()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pending_actions, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Sign Up",
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    children: [
                      TextSpan(
                        text: "Log in",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => PageLogIn()),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
