import 'package:beelingual/app_UI/account/ExchangePassword.dart';
import 'package:beelingual/app_UI/account/account_Information.dart';
import 'package:beelingual/component/profileProvider.dart';
import 'package:flutter/material.dart';
import 'package:beelingual/connect_api/api_connect.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AppColors {
  static const Color background = Color(0xFFFFFDE7);
  static const Color cardBackground = Color(0xFFFFF9C4);
  static const Color cardSelected = Color(0xFFFCE79A);
  static const Color iconActive = Color(0xFFEBC934);
  static const Color textDark = Color(0xFF5D4037);
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, color: Colors.grey[300]),
              const SizedBox(height: 20),
              const Text("Cài đặt", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text("Thông tin cá nhân"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (context) => const AccountInformation())
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text("Đổi mật khẩu"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (context) => ChangePasswordScreen(),)
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context); // Đóng modal
                  _handleLogout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              SessionManager().logout(context);
            },
            child: const Text("Đồng ý", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<UserProfileProvider>(context);
    final fullname = profileProvider.fullname;
    final isLoading = profileProvider.isLoading;
    final email = profileProvider.email;
    final joinDate = profileProvider.joinDate;
    final currentStreak = profileProvider.currentStreak;
    final xp = profileProvider.xp;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar trong suốt
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textDark, size: 28),
            onPressed: _showSettings, // Bấm vào bánh răng để mở cài đặt
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => profileProvider.reloadProfile(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Header (Avatar & Tên)
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullname ?? "Người dùng",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          // Thêm dấu chấm tròn ở giữa cho đẹp giống Duolingo
                          "${email ?? 'Chưa có email'}",
                          style: const TextStyle(color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amber, // viền vàng
                        width: 3, // độ dày viền
                      ),
                      image: DecorationImage(
                        image: AssetImage('assets/Images/logoBee.png'),
                        fit: BoxFit.cover, // tuỳ chỉnh: cover, contain, ...
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 5. Tổng quan (Overview Grid)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Tổng quan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildOverviewCard(
                      Icons.local_fire_department, "$currentStreak", "Ngày streak", Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildOverviewCard(
                      Icons.bolt, "$xp KN", "Tổng KN", Colors.amber)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildOverviewCard(Icons.emoji_events, "Chưa tham gia", "Giải đấu hiện tại", Colors.grey)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildOverviewCard(Icons.flag_circle, "10", "Điểm Tiếng Anh", Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 30),

              // 6. Streak bạn bè
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Streak bạn bè", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textDark, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: Text("Chưa có streak nào", style: TextStyle(color: AppColors.textDark))),
              ),
              const SizedBox(height: 30),

              // 7. Huy hiệu & Thành tích
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Thành tích", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {},
                    child: const Text("XEM TẤT CẢ", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 10),
              // Giả lập danh sách achievements
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildAchievementBadge(Colors.purpleAccent, "Mới"),
                    const SizedBox(width: 15),
                    _buildAchievementBadge(Colors.green, "Mới"),
                    const SizedBox(width: 15),
                    _buildAchievementBadge(Colors.redAccent, "Mới"),
                  ],
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // Widget con: Item thống kê text (Số lượng + Label)
  Widget _buildStatItem(String count, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: AppColors.textDark, fontSize: 12)),
      ],
    );
  }

  // Widget con: Card trong phần Tổng quan
  Widget _buildOverviewCard(IconData icon, String value, String title, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textDark, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(title, style: const TextStyle(color: AppColors.textDark, fontSize: 12), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Widget con: Badge thành tích
  Widget _buildAchievementBadge(Color color, String badgeText) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Icon(Icons.star, color: color, size: 40),
        ),
        Positioned(
          top: -5,
          right: -5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }
}