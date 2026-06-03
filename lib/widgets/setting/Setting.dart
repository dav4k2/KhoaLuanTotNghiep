import 'package:flutter/material.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  // Màu xanh chủ đạo của app
  final Color primaryGreen = const Color(0xFF1E6E38);
  // Màu xanh đậm cho các thẻ (cards) cài đặt
  final Color darkCardColor = const Color(0xFF164A28);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Nền trắng giúp nổi bật thẻ xanh đậm
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            children: [
              // Header: Icon + Chữ "Cài đặt"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/Icon_preview_rev_1.png',
                    width: 60,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cài đặt',
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Các khối cài đặt
              _buildSettingGroup(
                title: 'Ứng dụng',
                icon: Icons.settings_outlined,
                items: ['Ngôn ngữ', 'Thông báo', 'Chế độ tối/sáng'],
              ),
              _buildSettingGroup(
                title: 'Dữ liệu',
                icon: Icons.cloud_outlined,
                items: ['Đồng bộ hóa', 'Xóa dữ liệu cache'],
              ),
              _buildSettingGroup(
                title: 'Hỗ trợ',
                icon: Icons.help_outline,
                items: ['Trợ giúp & Phản hồi', 'Về ứng dụng'],
              ),

              const SizedBox(height: 10),

              // Nút "Quay lại"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkCardColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Quay lại',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget dùng chung để tạo ra một khối (card) cài đặt
  Widget _buildSettingGroup({
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon chính của khối (nằm bên trái)
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 16),
          // Cột chứa Tiêu đề và Danh sách các mục
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Tạo danh sách các mục cài đặt từ mảng `items`
                ...items.map((itemTitle) => _buildSettingItem(itemTitle)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget cho từng dòng cài đặt (VD: Thông tin cá nhân, Ngôn ngữ...)
  Widget _buildSettingItem(String text) {
    return InkWell(
      onTap: () {
        // TODO: Xử lý sự kiện khi click vào từng mục (ví dụ: mở dialog, chuyển trang)
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            // Dấu mũi tên Chevron ở góc phải
            const Icon(
              Icons.chevron_right,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}