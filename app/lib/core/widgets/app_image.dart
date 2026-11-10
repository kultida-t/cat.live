import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const _assetPrefix = 'asset:';
const _filePrefix = 'file:';

/// แสดงรูปจาก URL, `asset:<path>` (ข้อมูล mock ใช้รูปในแอป) หรือ `file:<path>` (รูปที่เลือกจากเครื่อง)
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.cacheWidth,
  });

  final String source;
  final BoxFit fit;
  final String? semanticLabel;

  /// ย่อรูปตอน decode (พิกเซล) — ใช้กับรูปย่อเพื่อประหยัดหน่วยความจำ
  final int? cacheWidth;

  /// provider ของรูปเดียวกัน — ใช้กับ precacheImage เพื่ออุ่นแคชก่อนเลื่อนถึง
  static ImageProvider providerOf(String source) {
    if (source.startsWith(_assetPrefix)) {
      return AssetImage(source.substring(_assetPrefix.length));
    }
    if (source.startsWith(_filePrefix)) {
      return FileImage(File(source.substring(_filePrefix.length)));
    }
    return NetworkImage(source);
  }

  @override
  Widget build(BuildContext context) {
    if (source.startsWith(_assetPrefix) || source.startsWith(_filePrefix)) {
      return Image(
        image: ResizeImage.resizeIfNeeded(cacheWidth, null, providerOf(source)),
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
