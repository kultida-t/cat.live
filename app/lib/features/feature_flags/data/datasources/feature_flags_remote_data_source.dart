import 'package:dio/dio.dart';

import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/feature_flags_data.dart';

/// สัญญาแหล่งข้อมูล Remote สำหรับ Feature Flags (OPS-04)
abstract interface class FeatureFlagsRemoteDataSource {
  Future<FeatureFlagsSnapshot> fetchRemoteFlags({
    required String platform,
    required String appVersion,
  });
}

/// แหล่งข้อมูล Mock ตามมติ DEC-01..11 และ OPS-04 (Phase 1 MVP Default)
class MockFeatureFlagsRemoteDataSource
    implements FeatureFlagsRemoteDataSource {
  const MockFeatureFlagsRemoteDataSource({
    this.latency = const Duration(milliseconds: 120),
  });

  final Duration latency;

  @override
  Future<FeatureFlagsSnapshot> fetchRemoteFlags({
    required String platform,
    required String appVersion,
  }) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }

    final flags = <AppFeatureFlag, bool>{
      for (final meta in FeatureFlagMetadata.catalog)
        meta.flag: meta.defaultEnabled,
    };

    // กติกา DEC-09 / STORE-01: บน iOS เปิด Flag สั่งซื้อ Tag ผ่านเว็บภายนอกเสมอ
    if (platform.toLowerCase() == 'ios') {
      flags[AppFeatureFlag.tagIosExternalWebOrder] = true;
    }

    return FeatureFlagsSnapshot(
      flags: flags,
      platform: platform,
      appVersion: appVersion,
      minSupportedVersion: '1.0.0',
      updatedAt: DateTime.now(),
    );
  }
}

/// แหล่งข้อมูล Backend API จริง (พร้อมสลับใช้งานเมื่อเปิด Backend OPS-04)
class DioFeatureFlagsRemoteDataSource implements FeatureFlagsRemoteDataSource {
  const DioFeatureFlagsRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<FeatureFlagsSnapshot> fetchRemoteFlags({
    required String platform,
    required String appVersion,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/config/flags',
        queryParameters: {'platform': platform, 'version': appVersion},
      );
      final body = response.data ?? const <String, dynamic>{};
      final rawFlags = body['flags'] as Map<String, dynamic>? ?? const {};

      final parsedFlags = <AppFeatureFlag, bool>{};
      for (final meta in FeatureFlagMetadata.catalog) {
        final rawValue = rawFlags[meta.key];
        parsedFlags[meta.flag] = rawValue is bool
            ? rawValue
            : meta.defaultEnabled;
      }

      return FeatureFlagsSnapshot(
        flags: parsedFlags,
        platform: body['platform'] as String? ?? platform,
        appVersion: appVersion,
        minSupportedVersion: body['min_supported_version'] as String? ?? '1.0.0',
        updatedAt: DateTime.tryParse(body['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
