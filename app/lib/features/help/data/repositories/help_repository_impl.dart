import '../../domain/entities/help_data.dart';
import '../../domain/repositories/help_repository.dart';
import '../datasources/help_remote_data_source.dart';

class HelpRepositoryImpl implements HelpRepository {
  HelpRepositoryImpl(this._dataSource);

  final HelpRemoteDataSource _dataSource;

  @override
  Future<HelpSnapshot> fetchHelpData() => _dataSource.fetchHelpData();

  @override
  Future<HelpPost> createHelpPost(CreateHelpPostInput input) =>
      _dataSource.createHelpPost(input);

  @override
  Future<void> sendClue(String postId) => _dataSource.sendClue(postId);

  @override
  Future<void> updatePostStatus(String postId, HelpPostStatus status) =>
      _dataSource.updatePostStatus(postId, status);

  @override
  Future<void> setDonationClosed(String postId, bool isClosed) =>
      _dataSource.setDonationClosed(postId, isClosed);

  @override
  Future<void> updatePostContent(
    String postId, {
    required String title,
    required String summary,
    required String location,
  }) =>
      _dataSource.updatePostContent(
        postId,
        title: title,
        summary: summary,
        location: location,
      );
}
