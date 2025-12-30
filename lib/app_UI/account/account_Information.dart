import 'package:beelingual_app/connect_api/api_connect.dart';
import 'package:beelingual_app/model/user.dart';
import 'package:flutter/material.dart';

class AccountInformation extends StatefulWidget {
  const AccountInformation({super.key});

  @override
  State<AccountInformation> createState() => _AccountInformationState();
}

class _AccountInformationState extends State<AccountInformation> with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  late Future<Map<String, dynamic>?> _profileFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();

  // Modern color palette
  final Color _primaryColor = const Color(0xFFFFB800);
  final Color _secondaryColor = const Color(0xFFFFC947);
  final Color _accentColor = const Color(0xFFFF9500);
  final Color _textPrimary = const Color(0xFF2C2C2C);
  final Color _textSecondary = const Color(0xFF757575);

  String _currentUsername = "";
  String _currentLevel = "";
  String _xp = "";
  String _gems = "";
  String _role ="";

  @override
  void initState() {
    super.initState();
    _profileFuture = fetchUserProfile(context);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _profileFuture = fetchUserProfile(context);
    });
  }

  void _toggleEditing(User? currentUser) {
    if (_isEditing) {
      _animationController.reverse();
      setState(() {
        _isEditing = false;
        if (currentUser != null) {
          _fullNameController.text = currentUser.fullname;
          _emailController.text = currentUser.email;
          _levelController.text = currentUser.level;
        }
      });
    } else {
      _animationController.forward();
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
      _animationController.reverse();
      setState(() {
        _isEditing = false;
        _refreshData();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text("Cập nhật thành công!", style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text("Cập nhật thất bại. Vui lòng thử lại!", style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _mapDataToControllers(User user, Map<String, dynamic> json) {
    _fullNameController.text = user.fullname;
    _emailController.text = user.email;
    _levelController.text = user.level;
    _currentLevel = user.level;
    _currentUsername = json['username']?.toString() ?? user.fullname;
    _role = json['role']?.toString() ?? user.role;
    _xp = "${json['xp']?.toString() ?? '0'} XP";
    _gems = "${json['gems']?.toString() ?? '0'} Gems";
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: _textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          "Account Information",
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isEditing ? Colors.red[50] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isEditing ? Icons.close_rounded : Icons.edit_outlined,
                color: _isEditing ? Colors.red : _accentColor,
                size: 22,
              ),
              onPressed: () async {
                final snapshot = await _profileFuture;
                if (snapshot != null) {
                  final user = User.fromJson(snapshot);
                  setState(() {
                    _mapDataToControllers(user, snapshot);
                  });
                  _toggleEditing(user);
                }
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "Lỗi tải thông tin",
                    style: TextStyle(color: _textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final userData = snapshot.data!;
          final currentUser = User.fromJson(userData);

          if (!_isEditing) {
            _mapDataToControllers(currentUser, userData);
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeaderGradient(),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildProfileCard(currentUser),
                        const SizedBox(height: 20),
                        _buildStatsCards(),
                        const SizedBox(height: 20),
                        _buildInfoCard(currentUser),
                        const SizedBox(height: 30),
                        if (_isEditing)
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildSaveButton(),
                          ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderGradient() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, _secondaryColor, _accentColor],
        ),
      ),
    );
  }

  Widget _buildProfileCard(User user) {
    bool isStudent = _role.toLowerCase() == 'student';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_primaryColor, _accentColor],
                  ),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: const AssetImage('assets/Images/logoBee.png'),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green[400],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.verified, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isStudent
                    ? [Colors.green[400]!, Colors.green[600]!]
                    : [Colors.red[400]!, Colors.red[600]!],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  _role,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentUsername,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _isEditing
              ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _fullNameController,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
              decoration: InputDecoration(
                hintText: "Fullname",
                hintStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
              ),
            ),
          )
              : Text(
            user.fullname.isNotEmpty ? user.fullname : "Fullname",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.bolt_rounded,
            label: "Experience",
            value: _xp,
            gradient: [Colors.purple[400]!, Colors.purple[600]!],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.diamond_rounded,
            label: "Gems",
            value: _gems,
            gradient: [Colors.blue[400]!, Colors.blue[600]!],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(User currentUser) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildModernInfoRow(
            icon: Icons.email_rounded,
            iconColor: Colors.orange[600]!,
            iconBgColor: Colors.orange[50]!,
            label: "Email Address",
            value: currentUser.email,
            controller: _emailController,
            isEditable: true,
          ),
          _buildDivider(),
          _buildModernInfoRow(
            icon: Icons.school_rounded,
            iconColor: Colors.blue[600]!,
            iconBgColor: Colors.blue[50]!,
            label: "Current Level",
            value: currentUser.level,
            controller: _levelController,
            isEditable: false,
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    TextEditingController? controller,
    bool isEditable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                (_isEditing && isEditable && controller != null)
                    ? TextField(
                  controller: controller,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    isDense: true,
                  ),
                )
                    : Text(
                  controller?.text ?? value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (_isEditing && isEditable)
            Icon(Icons.edit_rounded, color: _primaryColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey[200],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _accentColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _updateProfile,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  "Save Changes",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
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