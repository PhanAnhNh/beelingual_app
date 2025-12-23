import 'package:beelingual/app_UI/account/logIn.dart';
import 'package:beelingual/app_UI/account/termPage.dart';
import 'package:beelingual/component/messDialog.dart';
import 'package:beelingual/connect_api/api_connect.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class PageSignUp extends StatefulWidget {
  const PageSignUp({super.key});

  @override
  _PageSignUpState createState() => _PageSignUpState();
}

class _PageSignUpState extends State<PageSignUp> with SingleTickerProviderStateMixin {
  bool seePass = true;
  bool seeConPass = true;
  bool agreeTerms = false;
  bool _isLoading = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController conPassController = TextEditingController();
  String role = 'student';
  final session = SessionManager();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ✨ Original Yellow/Amber color scheme - Enhanced
  static const Color primaryAmber = Color(0xFFFFC107);      // Main amber
  static const Color darkAmber = Color(0xFFFF8F00);         // Darker amber for gradient
  static const Color lightYellow = Color(0xFFFFF9C4);       // Background yellow
  static const Color creamWhite = Color(0xFFFFFDE7);        // Lighter cream
  static const Color accentBlue = Color(0xFF1E88E5);        // Link blue
  static const Color textDark = Color(0xFF3E2723);          // Dark brown text

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    usernameController.dispose();
    fullnameController.dispose();
    emailController.dispose();
    passController.dispose();
    conPassController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: darkAmber, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: creamWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: Colors.brown.shade400, fontSize: 14),
      hintStyle: TextStyle(color: Colors.brown.shade300, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.amber.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryAmber, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lightYellow, creamWhite],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: isSmallScreen ? 12 : 20,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🐝 Logo với icon bee hoặc user
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [primaryAmber, darkAmber],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryAmber.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          color: textDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tạo tài khoản BeeLingual',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.brown.shade400,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Form fields
                      TextField(
                        controller: fullnameController,
                        style: const TextStyle(fontSize: 15, color: textDark),
                        decoration: _buildInputDecoration(
                          label: "Fullname",
                          hint: "",
                          icon: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: usernameController,
                        style: const TextStyle(fontSize: 15, color: textDark),
                        decoration: _buildInputDecoration(
                          label: "Username",
                          hint: "Bee1234",
                          icon: Icons.account_circle_outlined,
                          suffixIcon: Tooltip(
                            message:
                            "Tên đăng nhập không được chứa khoảng trắng\n",
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.brown.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.brown,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 15, color: textDark),
                        decoration: _buildInputDecoration(
                          label: "Email",
                          hint: "example@gmail.com",
                          icon: Icons.email_outlined,
                          suffixIcon: Tooltip(
                            message:
                            "Email phải đúng định dạng\n"
                                "Không chứa khoảng trắng\n"
                                "Ví dụ: example@gmail.com",
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.brown.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.brown,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passController,
                        obscureText: seePass,
                        style: const TextStyle(fontSize: 15, color: textDark),
                        decoration: _buildInputDecoration(
                          label: "Password",
                          hint: "Bee@1234",
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              seePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.brown.shade400,
                              size: 20,
                            ),
                            onPressed: () => setState(() => seePass = !seePass),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: conPassController,
                        obscureText: seeConPass,
                        style: const TextStyle(fontSize: 15, color: textDark),
                        decoration: _buildInputDecoration(
                          label: "Confirm Password",
                          hint: "",
                          icon: Icons.lock_reset_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              seeConPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.brown.shade400,
                              size: 20,
                            ),
                            onPressed: () => setState(() => seeConPass = !seeConPass),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Terms checkbox
                      InkWell(
                        onTap: () => setState(() => agreeTerms = !agreeTerms),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: agreeTerms ? primaryAmber : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: agreeTerms ? primaryAmber : Colors.brown.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: agreeTerms
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Tôi đồng ý với ',
                                    style: TextStyle(color: Colors.brown.shade500, fontSize: 13),
                                    children: [
                                      TextSpan(
                                        text: 'Điều khoản sử dụng',
                                        style: const TextStyle(
                                          color: accentBlue,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const TermsPage()),
                                          ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sign Up button - Amber gradient
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryAmber, darkAmber],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: primaryAmber.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.how_to_reg_rounded, size: 22),
                              SizedBox(width: 10),
                              Text(
                                "Sign Up",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(fontSize: 14, color: Colors.brown.shade500),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              "Log in",
                              style: TextStyle(
                                fontSize: 14,
                                color: accentBlue,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    String user = usernameController.text.trim();
    String name = fullnameController.text.trim();
    String email = emailController.text.trim();
    String pass = passController.text.trim();
    String conPass = conPassController.text.trim();

    if (!session.isValidUsername(user)) {
      showErrorDialog(context, "Chú ý", "Tên đăng nhập không được có khoảng trắng");
      return;
    }

    if (!session.isValidEmail(email)) {
      showErrorDialog(context, "Chú ý", "Email phải đúng định dạng (example@gmail.com)");
      return;
    }

    if (!session.isValidPassword(pass)) {
      showErrorDialog(context, "Chú ý", "Mật khẩu phải tối thiểu 6 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt");
      return;
    }

    if (!agreeTerms) {
      showErrorDialog(context, "Chú ý", "Bạn phải đồng ý với Điều khoản sử dụng.");
      return;
    }

    if (user.isEmpty || name.isEmpty || email.isEmpty || pass.isEmpty || conPass.isEmpty) {
      showErrorDialog(context, "Chú ý", "Vui lòng nhập đầy đủ thông tin!");
      return;
    }

    if (pass != conPass) {
      showErrorDialog(context, "Lỗi", "Mật khẩu không khớp!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await session.signUp(
        username: user,
        email: email,
        fullname: name,
        password: pass,
        role: role,
      );

      session.signUpSupabase(email: email, password: pass);

      if (res == null) {
        showErrorDialog(context, "Lỗi", "Lỗi không xác định!");
        return;
      }

      if (res["error"] == true) {
        showErrorDialog(context, "Lỗi", res["message"]);
      } else {
        await showSuccessDialog(context, "Thành công", "Đăng ký thành công!");
        Navigator.push(context, MaterialPageRoute(builder: (_) => PageLogIn()));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}