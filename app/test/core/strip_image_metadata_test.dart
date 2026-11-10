import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:catlive/core/media/strip_image_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> _png(int w, int h) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFE8915C),
  );
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<ui.Image> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

void main() {
  test('เข้ารหัสใหม่เป็น PNG และขนาดเดิมถ้าเล็กกว่าเพดาน', () async {
    final out = await stripImageMetadata(await _png(40, 20));

    expect(out.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    final image = await _decode(out);
    expect([image.width, image.height], [40, 20]);
  });

  test('รูปใหญ่เกินเพดาน — ย่อด้านยาวให้พอดี รักษาสัดส่วน', () async {
    final out = await stripImageMetadata(await _png(400, 100), maxSide: 200);

    final image = await _decode(out);
    expect([image.width, image.height], [200, 50]);
  });
}
