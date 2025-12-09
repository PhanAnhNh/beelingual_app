import 'package:beelingual/component/messDialog.dart';
import 'package:beelingual/signUp.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'controller/accountController.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PageLogIn extends StatefulWidget {
  const PageLogIn({super.key});

  @override
  _PageLogInState createState() => _PageLogInState();
}

class _PageLogInState extends State<PageLogIn> {
  bool seePass = true;
  final TextEditingController username = TextEditingController();
  final TextEditingController pass = TextEditingController();
  final session = SessionManager();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xFFFFF9C4),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                SizedBox(height: 100),
                Image.asset(
                  "asset/Images/logo.png",
                  width: 200,
                  height: 200,
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'Welcome to Beelingual',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                SizedBox(height: 5),
                TextField(
                  controller: this.username,
                  style: TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: "Username",
                    hint: Text('admin_pro'),
                    labelStyle: TextStyle(fontSize: 15),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: this.pass,
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
                          seePass = !seePass; // Đổi trạng thái ẩn/hiện
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    String usernameText = username.text.trim();
                    String passwordText = pass.text.trim();

                    if (usernameText.isEmpty || passwordText.isEmpty) {
                      showErrorDialog(context, "Vui lòng nhập đầy đủ thông tin");
                      return;
                    }

                    Map<String, dynamic>? token = await session.login(username: usernameText, password: passwordText);

                    if (token != null) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('accessToken', token['accessToken']!);
                      await prefs.setString('refreshToken', token['refreshToken']!);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => PageHome()),
                      );
                    } else {
                      showErrorDialog(context, "Đăng nhập thất bại!!!");
                    }

                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.login, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Log in",
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 5),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => PageSignUp()),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pending_actions, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        "Sign up",
                        style: TextStyle(fontSize: 15, color: Colors.amber),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 5),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Xử lý nhấn quên mật khẩu ở đây
                      //Lấy mã OTP,...vv
                    },
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.underline, // gạch chân
                        color: Colors.black,
                        fontStyle: FontStyle.italic// màu link
                      ),
                    ),
                  ),
                )

              ],
            ),
          ),
        ),
      ),
    );
  }
}
