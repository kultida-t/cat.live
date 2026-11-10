import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// ไอคอน lucide แบบเลือกทึบ/โปร่งได้ (ชุดไอคอน Flutter ไม่มีแบบทึบ จึงวาดจาก SVG เดียวกับเว็บ)
enum FillIconShape {
  heart(
    '<path d="M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5"/>',
  ),
  bookmark('<path d="m19 21-7-4-7 4V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v16z"/>');

  const FillIconShape(this.path);
  final String path;
}

class FillIcon extends StatelessWidget {
  const FillIcon({
    super.key,
    required this.shape,
    required this.color,
    this.filled = false,
    this.size = 24,
  });

  final FillIconShape shape;
  final Color color;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hex =
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
        'fill="${filled ? hex : 'none'}" stroke="$hex" stroke-width="1.8" '
        'stroke-linecap="round" stroke-linejoin="round">${shape.path}</svg>';
    return SvgPicture.string(svg, width: size, height: size);
  }
}
