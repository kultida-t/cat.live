import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/cat_ai_remote_data_source.dart';
import '../../data/datasources/mock_cat_ai_data_source.dart';
import '../../data/repositories/cat_ai_repository_impl.dart';
import '../../domain/repositories/cat_ai_repository.dart';

final catAiDataSourceProvider = Provider<CatAiRemoteDataSource>((ref) {
  return MockCatAiDataSource();
});

final catAiRepositoryProvider = Provider<CatAiRepository>((ref) {
  return CatAiRepositoryImpl(ref.watch(catAiDataSourceProvider));
});
