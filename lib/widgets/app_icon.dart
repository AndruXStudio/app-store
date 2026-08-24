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
    final u = url?.trim() ?? '';
    Widget child;

    if (u.startsWith('data:image')) {
      try {
        final b64 = u.split(',').last;
        final bytes = base64Decode(b64);
        child = Image.memory(bytes, width: size, height: size, fit: BoxFit.cover);
      } catch (_) {
        child = _fallback(context);
      }
    } else if (u.startsWith('http')) {
      child = CachedNetworkImage(
        imageUrl: u,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallback(context),
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          color: Colors.grey.shade300,
          child: const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
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
    final letter = name.isNotEmpty ? name.characters.first : '?';
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
