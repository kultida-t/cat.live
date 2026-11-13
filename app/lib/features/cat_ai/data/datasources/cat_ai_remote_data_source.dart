import 'dart:typed_data';

import '../../domain/entities/cat_ai_data.dart';

abstract interface class CatAiRemoteDataSource {
  Future<CatAiSnapshot> fetchSnapshot();

  Future<String> ask(String question, {required bool detailed});

  Future<CatAiImageReply> analyzeImage(Uint8List bytes, String question);
}
