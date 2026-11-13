import '../../domain/entities/cat_ai_data.dart';

abstract interface class CatAiRemoteDataSource {
  Future<CatAiSnapshot> fetchSnapshot();

  Future<String> ask(String question, {required bool detailed});
}
