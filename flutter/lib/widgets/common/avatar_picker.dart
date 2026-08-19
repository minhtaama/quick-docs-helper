import 'dart:typed_data';
import 'package:flutter/material.dart';

class AvatarPicker extends StatelessWidget {
  final Uint8List? avatarBytes;
  final String? initialImageUrl;
  final VoidCallback onPickAvatar;
  final VoidCallback? onRemoveAvatar;
  final double aspectRatio;

  const AvatarPicker({
    super.key,
    required this.avatarBytes,
    this.initialImageUrl,
    required this.onPickAvatar,
    this.onRemoveAvatar,
    this.aspectRatio = 4 / 6,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    Widget imageWidget;
    if (avatarBytes != null) {
      imageWidget = Image.memory(
        avatarBytes!,
        fit: BoxFit.cover,
      );
    } else if (initialImageUrl != null && initialImageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        initialImageUrl!,
        key: ValueKey(initialImageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 40,
              color: primaryColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              'Ảnh 4x6',
              style: TextStyle(
                fontSize: 11,
                color: primaryColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    } else {
      imageWidget = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 40,
            color: primaryColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 4),
          Text(
            'Ảnh 4x6',
            style: TextStyle(
              fontSize: 11,
              color: primaryColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: imageWidget,
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: InkWell(
              onTap: onPickAvatar,
              borderRadius: BorderRadius.circular(16),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: primaryColor,
                child: const Icon(Icons.upload, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
