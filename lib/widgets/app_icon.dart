import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppIcon extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  final double radius;

  const AppIcon({
    super.key,
    required this.url,
    required this.name,
    this.size = 56,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final u = (url ?? '').trim();
    Widget child;

    if (u.startsWith('data:image') && u.contains(',')) {
      try {
        final bytes = base64Decode(u.split(',').last);
        child = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(context),
        );
      } catch (_) {
        child = _fallback(context);
      }
    } else if (u.startsWith('http://') || u.startsWith('https://')) {
      child = CachedNetworkImage(
        imageUrl: u,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: (size * 3).toInt(),
        fadeInDuration: Duration.zero,
        errorWidget: (_, __, ___) => _fallback(context),
        placeholder: (_, __) => _fallback(context),
      );
    } else {
      child = _fallback(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: child),
    );
  }

  Widget _fallback(BuildContext context) {
    final letter = name.trim().isNotEmpty ? name.trim().characters.first : 'A';
    return Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
