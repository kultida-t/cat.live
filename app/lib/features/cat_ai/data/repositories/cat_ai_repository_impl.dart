import 'dart:typed_data';

import '../../domain/entities/cat_ai_data.dart';
import '../../domain/repositories/cat_ai_repository.dart';
import '../datasources/cat_ai_remote_data_source.dart';

class CatAiRepositoryImpl implements CatAiRepository {
  CatAiRepositoryImpl(this._remote);

  final CatAiRemoteDataSource _remote;

  @override
  Future<CatAiSnapshot> fetchSnapshot() => _remote.fetchSnapshot();

  @override
  Future<String> ask(String question, {required bool detailed}) =>
      _remote.ask(question, detailed: detailed);

  @override
  Future<CatAiImageReply> analyzeImage(Uint8List bytes, String question) =>
      _remote.analyzeImage(bytes, question);
}
