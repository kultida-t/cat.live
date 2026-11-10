import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const _assetPrefix = 'asset:';

/// แสดงรูปจาก URL หรือ `asset:<path>` (ข้อมูล mock ใช้รูปในแอป)
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final String source;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (source.startsWith(_assetPrefix)) {
      return Image.asset(
        source.substring(_assetPrefix.length),
        fit: fit,
        semanticLabel: semanticLabel,
        gaplessPlayback: true,
      );
    }
    return Image.network(
      source,
      fit: fit,
      semanticLabel: semanticLabel,
      gaplessPlayback: true,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : const ColoredBox(color: AppColors.media),
      errorBuilder: (_, _, _) => const ColoredBox(
        color: AppColors.media,
        child: Center(child: Icon(Icons.pets, color: AppColors.unchecked)),
      ),
    );
  }
}
