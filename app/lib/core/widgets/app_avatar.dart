import 'package:flutter/material.dart';

import 'app_image.dart';

/// อวตารวงกลม — สีพื้นโชว์ระหว่างรอรูปโหลด
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.source,
    required this.bg,
    required this.size,
  });

  final String source;
  final int bg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Color(bg)),
      clipBehavior: Clip.antiAlias,
      child: AppImage(source: source),
    );
  }
}
