import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart';

class AssetCacheService {
  static final AssetCacheService _instance = AssetCacheService._internal();
  factory AssetCacheService() => _instance;
  AssetCacheService._internal();

  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  /// Pre-caches a list of URLs
  Future<void> preCacheAssets(List<String> urls) async {
    for (final url in urls) {
      try {
        await _cacheManager.downloadFile(url);
      } catch (e) {
        debugPrint('Error pre-caching asset $url: $e');
      }
    }
  }

  /// Helper for specific course assets
  Future<void> cacheCourseFlags(List<String> flagUrls) async {
    await preCacheAssets(flagUrls);
  }

  /// New helper to match CourseProvider call
  Future<void> cacheCourseAssets(dynamic course) async {
    if (course == null) return;
    // Cache the flag for now, can be extended for other assets
    final flagUrl = course.targetLanguageFlag;
    if (flagUrl != null && flagUrl.startsWith('http')) {
      await preCacheAssets([flagUrl]);
    }
  }
}
