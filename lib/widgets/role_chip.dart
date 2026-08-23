import 'package:flutter/material.dart';

class RoleChip extends StatelessWidget {
  final String role;
  const RoleChip({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    late String label;
    switch (role) {
      case 'creator':
        bg = Colors.deepPurple.shade100;
        fg = Colors.deepPurple.shade800;
        label = '创建者';
        break;
      case 'admin':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
        label = '管理员';
        break;
      default:
        bg = Colors.blueGrey.shade100;
        fg = Colors.blueGrey.shade800;
        label = '用户';
    }
    return Chip(
      label: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
      backgroundColor: bg,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
