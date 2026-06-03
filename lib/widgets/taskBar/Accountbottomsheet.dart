// lib/widgets/taskBar/AccountBottomSheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/auth/auth_notifier.dart';
import '../../core/storage/token_storage.dart';

class AccountBottomSheet extends ConsumerWidget {
  const AccountBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Thông tin tài khoản — hiển thị họ tên ────────
            const _AccountInfoTile(),

            const Divider(height: 1, thickness: 0.5),

            _MenuItem(
              icon:     Icons.settings_outlined,
              label:    'Cài đặt',
              shortcut: '⇧+Ctrl+,',
              onTap:    () => Navigator.pop(context),
            ),
            _MenuItem(
              icon:     Icons.language_outlined,
              label:    'Ngôn ngữ',
              trailing: const Icon(Icons.chevron_right, color: Colors.black54),
              onTap:    () => Navigator.pop(context),
            ),
            _MenuItem(
              icon:          Icons.help_outline,
              label:         'Trợ giúp',
              isHighlighted: true,
              onTap:         () => Navigator.pop(context),
            ),

            const Divider(height: 1, thickness: 0.5),

            _MenuItem(
              icon:  Icons.logout,
              label: 'Đăng xuất',
              color: Colors.red.shade600,
              onTap: () => _handleLogout(context, ref),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    final navigator = Navigator.of(context);
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Huỷ',
                style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Đăng xuất',
                style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).then((confirm) async {
      if (confirm == true) {
        await ref.read(authNotifierProvider.notifier).logout();
        navigator.pushNamedAndRemoveUntil('/login', (_) => false);
      }
    });
  }
}

// ── Widget hiển thị avatar + họ tên + email ──────────────────

class _AccountInfoTile extends StatefulWidget {
  const _AccountInfoTile();

  @override
  State<_AccountInfoTile> createState() => _AccountInfoTileState();
}

class _AccountInfoTileState extends State<_AccountInfoTile> {
  String _email    = '';
  String _fullName = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final email    = await TokenStorage.getEmail()    ?? '';
    final fullName = await TokenStorage.getFullName() ?? '';
    if (mounted) {
      setState(() {
        _email    = email;
        _fullName = fullName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy chữ cái đầu của họ tên (hoặc email nếu chưa có họ tên)
    final displayName = _fullName.isNotEmpty ? _fullName : _email;
    final initial     = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'U';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Avatar tròn
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF1E6E38),
            child: Text(
              initial,
              style: const TextStyle(
                color:      Colors.white,
                fontWeight: FontWeight.bold,
                fontSize:   20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Họ tên + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Họ tên (nổi bật)
                if (_fullName.isNotEmpty)
                  Text(
                    _fullName,
                    style: const TextStyle(
                      fontSize:   16,
                      fontWeight: FontWeight.bold,
                      color:      Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                // Email (nhỏ hơn)
                Text(
                  _email,
                  style: TextStyle(
                    fontSize: _fullName.isNotEmpty ? 13 : 15,
                    color:    _fullName.isNotEmpty
                        ? Colors.black54
                        : Colors.black87,
                    fontWeight: _fullName.isNotEmpty
                        ? FontWeight.normal
                        : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget item menu ──────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final String?   shortcut;
  final Widget?   trailing;
  final Color?    color;
  final bool      isHighlighted;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.shortcut,
    this.trailing,
    this.color,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.black87;
    return ListTile(
      leading: Icon(icon, color: effectiveColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color:      effectiveColor,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
          fontSize:   15,
        ),
      ),
      trailing: shortcut != null
          ? Text(shortcut!,
          style: const TextStyle(color: Colors.black38, fontSize: 12))
          : trailing,
      onTap:           onTap,
      dense:           true,
      contentPadding:  const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}