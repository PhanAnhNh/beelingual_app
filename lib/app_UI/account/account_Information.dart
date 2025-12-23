import 'package:beelingual/model/user.dart';
import 'package:flutter/material.dart';
import 'package:beelingual/connect_api/api_connect.dart';

class AccountInformation extends StatefulWidget {
  const AccountInformation({super.key});

  @override
  State<AccountInformation> createState() => _AccountInformationState();
}

class _AccountInformationState extends State<AccountInformation> {
  bool _isEditing = false;
  late Future<Map<String, dynamic>?> _profileFuture;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();

  final Color _bgColor = const Color(0xFFFFF8E7);
  final Color _cardColor = const Color(0xFFFFCA28);
  final Color _textColor = const Color(0xFF4E342E);

  // Biến hiển thị (Sẽ được gán giá trị từ API)
  String _currentUsername = "";
  String _currentLevel = "";
  String _xp = "";
  String _gems = "";

  @override
  void initState() {
    super.initState();
    _profileFuture = fetchUserProfile(context);
  }

  void _refreshData() {
    setState(() {
      _profileFuture = fetchUserProfile(context);
    });
  }

  void _toggleEditing(User? currentUser) {
    if (_isEditing) {
      setState(() {
        _isEditing = false;
        if (currentUser != null) {
          _fullNameController.text = currentUser.fullname;
          _emailController.text = currentUser.email;
          _levelController.text = currentUser.level;
        }
      });
    } else {
      setState(() {
        _isEditing = true;
      });
    }
  }

  Future<void> _updateProfile() async {
    final newFullName = _fullNameController.text;
    final newEmail = _emailController.text;
    final currentLevelToSend = _currentLevel;

    final success = await updateUserInfo(
      fullName: newFullName,
      email: newEmail,
      level: currentLevelToSend,
      context: context,
    );

    if (success) {
      setState(() {
        _isEditing = false;
        _refreshData();
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thành công!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thất bại. Vui lòng thử lại!")));
    }
  }

  // --- HÀM QUAN TRỌNG: Map dữ liệu từ JSON API vào biến ---
  void _mapDataToControllers(User user, Map<String, dynamic> json) {
    _fullNameController.text = user.fullname;
    _emailController.text = user.email;
    _levelController.text = user.level;
    _currentLevel = user.level;

    // LẤY DỮ LIỆU TRỰC TIẾP TỪ JSON API
    // Bạn hãy kiểm tra lại key 'username', 'xp', 'gems' trong API của bạn xem đúng tên chưa nhé
    _currentUsername = json['username']?.toString() ?? user.fullname;
    _xp = "${json['xp']?.toString() ?? '0'} XP";
    _gems = "${json['gems']?.toString() ?? '0'} Gems";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Account Information",
          style: TextStyle(
              color: _textColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: _isEditing ? Colors.red : const Color(0xFFFBC02D),
            ),
            onPressed: () async {
              final snapshot = await _profileFuture;
              if (snapshot != null) {
                final user = User.fromJson(snapshot);
                // Map lại dữ liệu mới nhất trước khi sửa
                setState(() {
                  _mapDataToControllers(user, snapshot);
                });
                _toggleEditing(user);
              }
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text("Lỗi tải thông tin", style: TextStyle(color: _textColor)));
          }

          final userData = snapshot.data!;
          final currentUser = User.fromJson(userData);

          if (!_isEditing) {
            _mapDataToControllers(currentUser, userData);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildTopCard(currentUser),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.email_outlined,
                        iconColor: Colors.orange,
                        iconBgColor: const Color(0xFFFFF3E0),
                        label: "Email Address",
                        value: currentUser.email,
                        controller: _emailController,
                        isEditable: true,
                      ),
                      const Divider(height: 30, thickness: 0.5, indent: 70, endIndent: 20),

                      _buildInfoRow(
                        icon: Icons.star_outline,
                        iconColor: Colors.blue,
                        iconBgColor: const Color(0xFFE3F2FD),
                        label: "Current Level",
                        value: currentUser.level,
                        controller: _levelController,
                        isEditable: false,
                      ),
                      const Divider(height: 30, thickness: 0.5, indent: 70, endIndent: 20),

                      // Hiển thị XP lấy từ API
                      _buildInfoRow(
                          icon: Icons.bolt,
                          iconColor: const Color(0xFFBCAAA4),
                          iconBgColor: const Color(0xFFFFF8E1),
                          label: "Experience Points",
                          value: _xp,
                          isEditable: false,
                          isCustomField: true
                      ),
                      const Divider(height: 30, thickness: 0.5, indent: 70, endIndent: 20),

                      // Hiển thị Gems lấy từ API
                      _buildInfoRow(
                          icon: Icons.diamond_outlined,
                          iconColor: const Color(0xFF8D6E63),
                          iconBgColor: const Color(0xFFFFF8E1),
                          label: "Total Gems",
                          value: _gems,
                          isEditable: false,
                          isCustomField: true
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                if (_isEditing)
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cardColor,
                      foregroundColor: _textColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopCard(User user) {
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[300],
              backgroundImage: const AssetImage('assets/images/book_login.png'),
              child: const Icon(Icons.person, size: 40, color: Colors.white),
            ),
          ),

          Positioned(
            top: 30,
            left: 100,
            child: Text(
              _currentUsername, // Hiển thị Username từ API
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),

          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: const Text(
                "ADMIN",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: _isEditing
                ? TextField(
              controller: _fullNameController,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textColor),
              decoration: const InputDecoration(
                hintText: "Fullname",
                border: UnderlineInputBorder(),
              ),
            )
                : Text(
              user.fullname.isNotEmpty ? user.fullname : "Fullname",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    TextEditingController? controller,
    bool isEditable = false,
    bool isCustomField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                (_isEditing && isEditable && controller != null)
                    ? SizedBox(
                  height: 40,
                  child: TextField(
                    controller: controller,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textColor
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(bottom: 10),
                      border: UnderlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                )
                    : Text(
                  isCustomField ? value : (controller?.text ?? value),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                if (_isEditing && isEditable && controller != null)
                  Text("....................................................", style: TextStyle(color: Colors.grey[400], fontSize: 10), maxLines: 1, overflow: TextOverflow.clip,)
                else if (!isCustomField)
                  Text("....................................................", style: TextStyle(color: Colors.grey[400], fontSize: 10), maxLines: 1, overflow: TextOverflow.clip,)
              ],
            ),
          )
        ],
      ),
    );
  }
}