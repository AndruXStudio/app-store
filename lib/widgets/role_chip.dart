import 'package:flutter/material.dart';

class RoleChip extends StatelessWidget {
  final String role;
  const RoleChip({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final r = role.toLowerCase();
    late String label;
    late Color color;
    if (r == 'creator') {
      label = '创建者';
      color = Colors.purple;
    } else if (r == 'admin') {
      label = '管理员';
      color = Colors.orange;
    } else if (r == 'developer') {
      label = '开发者';
      color = Colors.blue;
    } else {
      label = '用户';
      color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
