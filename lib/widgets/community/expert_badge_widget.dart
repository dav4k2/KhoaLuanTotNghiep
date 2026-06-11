// lib/widgets/community/expert_badge.dart
//
// Widget hiển thị tên tác giả + dấu ★ nếu là chuyên gia
// Dùng ở bất kỳ đâu cần hiển thị tên user trong Community

import 'package:flutter/material.dart';

class AuthorNameBadge extends StatelessWidget {
  final String name;
  final String role;       // "user" | "expert" | "admin"
  final double fontSize;
  final FontWeight fontWeight;

  const AuthorNameBadge({
    super.key,
    required this.name,
    required this.role,
    this.fontSize   = 14,
    this.fontWeight = FontWeight.w600,
  });

  bool get _isExpert => role == 'expert';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize:   fontSize,
            fontWeight: fontWeight,
            color:      Colors.black87,
          ),
        ),
        if (_isExpert) ...[
          const SizedBox(width: 4),
          Tooltip(
            message: 'Chuyên gia',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color:        const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(4),
                border:       Border.all(color: const Color(0xFFFFD700), width: 0.8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '★',
                    style: TextStyle(
                      fontSize: 10,
                      color:    Color(0xFFB8860B),
                      height:   1.2,
                    ),
                  ),
                  SizedBox(width: 2),
                  Text(
                    'CG',
                    style: TextStyle(
                      fontSize:   9,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFFB8860B),
                      height:     1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
