import '../../domain/entities/help_data.dart';

/// แหล่งข้อมูลระยะไกลของหน้าช่วยเหลือ (Phase 2 เชื่อม API จริง)
abstract interface class HelpRemoteDataSource {
  Future<HelpSnapshot> fetchHelpData();

  Future<HelpPost> createHelpPost(CreateHelpPostInput input);

  Future<void> sendClue(String postId);

  Future<void> updatePostStatus(String postId, HelpPostStatus status);

  Future<void> setDonationClosed(String postId, bool isClosed);

  Future<void> updatePostContent(
    String postId, {
    required String title,
    required String summary,
    required String location,
  });
}
