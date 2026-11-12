import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/help_remote_data_source.dart';
import '../../data/datasources/mock_help_data_source.dart';
import '../../data/repositories/help_repository_impl.dart';
import '../../domain/repositories/help_repository.dart';

final helpDataSourceProvider = Provider<HelpRemoteDataSource>((ref) {
  return MockHelpDataSource();
});

final helpRepositoryProvider = Provider<HelpRepository>((ref) {
  return HelpRepositoryImpl(ref.watch(helpDataSourceProvider));
});
