import 'package:beelingual/connect_api/api_connect.dart';
import 'package:flutter/material.dart';
// Import hàm changePasswordAPI vừa viết ở trên
// import 'path/to/your/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // 1. Khởi tạo Controllers để lấy dữ liệu nhập vào
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  // Biến quản lý trạng thái
  bool _obscureCurrentPass = true;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  bool _isLoading = false; // Trạng thái đang tải
  String? _errorMessage;   // Chuỗi chứa lỗi để hiển thị màu đỏ

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- Hàm xử lý chính ---
  Future<void> _handleSubmit() async {
    // Reset lỗi cũ
    setState(() {
      _errorMessage = null;
    });

    final currentPass = _currentPassController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    // Validate phía Client trước
    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      setState(() => _errorMessage = "Vui lòng nhập đầy đủ thông tin");
      return;
    }

    if (newPass.length < 6 || newPass.length > 20) {
      setState(() => _errorMessage = "Mật khẩu mới phải từ 6 - 20 ký tự");
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorMessage = "Mật khẩu xác nhận không khớp");
      return;
    }

    // Bắt đầu gọi API
    setState(() => _isLoading = true);

    // Gọi hàm API đã viết
    final result = await changePasswordAPI(currentPass, newPass, context);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      // Thành công -> Hiện thông báo và quay lại hoặc logout
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Đổi mật khẩu thành công!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Quay về màn hình trước
    } else {
      // Thất bại -> Hiện lỗi lên màn hình (dòng chữ đỏ)
      setState(() {
        _errorMessage = result['message'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryYellow = Color(0xFFFFD54F);
    const Color bgCream = Color(0xFFFFFDE7);
    const Color borderColor = Color(0xFFFFE082);

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: primaryYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Đổi mật khẩu",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 30),
              height: 120,
              child: const Icon(Icons.lock_person_rounded, size: 80, color: Colors.orangeAccent),
            ),

            // 2. Ô mật khẩu hiện tại (Gắn controller)
            _buildPasswordField(
              controller: _currentPassController, // <--- THÊM
              hintText: "Nhập mật khẩu hiện tại",
              obscureText: _obscureCurrentPass,
              borderColor: borderColor,
              onToggleVisibility: () => setState(() => _obscureCurrentPass = !_obscureCurrentPass),
            ),
            const SizedBox(height: 15),

            // 3. Ô mật khẩu mới (Gắn controller)
            _buildPasswordField(
              controller: _newPassController, // <--- THÊM
              hintText: "Nhập mật khẩu mới",
              obscureText: _obscureNewPass,
              borderColor: borderColor,
              onToggleVisibility: () => setState(() => _obscureNewPass = !_obscureNewPass),
            ),

            const Padding(
              padding: EdgeInsets.only(top: 8.0, left: 5.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Mật khẩu từ 6 - 20 ký tự", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 15),

            // 4. Ô xác nhận mật khẩu (Gắn controller)
            _buildPasswordField(
              controller: _confirmPassController, // <--- THÊM
              hintText: "Nhập lại mật khẩu mới",
              obscureText: _obscureConfirmPass,
              borderColor: borderColor,
              onToggleVisibility: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
            ),

            // --- HIỂN THỊ LỖI ĐỘNG ---
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 5.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),

            const SizedBox(height: 40),

            // 5. Nút Lưu thay đổi (Xử lý Loading và OnPressed)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit, // Disable khi đang load
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryYellow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text("Lưu thay đổi", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 15),

            // 6. Nút Huỷ
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.black54, width: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("Huỷ", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cập nhật widget con để nhận Controller
  Widget _buildPasswordField({
    required TextEditingController controller, // <--- THÊM tham số này
    required String hintText,
    required bool obscureText,
    required Color borderColor,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: controller, // <--- Gắn controller vào đây
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange, width: 1.5)),
          suffixIcon: IconButton(
            icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.brown),
            onPressed: onToggleVisibility,
          ),
        ),
      ),
    );
  }
}