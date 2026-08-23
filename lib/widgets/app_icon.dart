import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 圆角正方形；加载失败或空 URL 时：黑底 + 白色 Android 图标
class AppIcon extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;

  const AppIcon({super.key, this.url, this.size = 48, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(Icons.android, color: Colors.white, size: size * 0.55),
    );

    if (url == null || url!.trim().isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}
