import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// ลบข้อมูลแฝงในรูป (เช่น พิกัด GPS ใน EXIF) ก่อนอัปโหลด โดยถอดรหัสเป็นพิกเซลแล้ว
/// เข้ารหัสใหม่เป็น PNG — ข้อมูลแฝงไม่ถูกคัดลอกตามมา และย่อด้านยาวไม่เกิน [maxSide]
/// (เซิร์ฟเวอร์ต้องตรวจ/ลบซ้ำอีกชั้นเสมอ ห้ามเชื่อแค่ฝั่งแอป)
Future<Uint8List> stripImageMetadata(
  Uint8List bytes, {
  int maxSide = 2048,
}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  try {
    final longSide = math.max(descriptor.width, descriptor.height);
    final scale = longSide > maxSide ? maxSide / longSide : 1.0;
    final codec = await descriptor.instantiateCodec(
      targetWidth: (descriptor.width * scale).round(),
      targetHeight: (descriptor.height * scale).round(),
    );
    final image = (await codec.getNextFrame()).image;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    codec.dispose();
    return data!.buffer.asUint8List();
  } finally {
    descriptor.dispose();
    buffer.dispose();
  }
}
