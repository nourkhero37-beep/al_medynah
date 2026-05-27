import 'package:al_medynah/model/tv_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class TvService {
  static final TvService _instance = TvService._internal();
  factory TvService() => _instance;
  TvService._internal();

  final Dio _dio = Dio();

  Future<List<LiveTvChannel>> fetchLiveTV() async {
    try {
      final response = await _dio.get(
        'https://mp3quran.net/api/v3/live-tv',
        queryParameters: {'language': 'ar'},
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      final list = response.data['livetv'] as List<dynamic>;
      return list
          .map((e) => LiveTvChannel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching live TV: ');
      return [];
    }
  }

  Future<List<VideoType>> fetchVideoTypes() async {
    try {
      final response = await _dio.get(
        'https://mp3quran.net/api/v3/video_types',
        queryParameters: {'language': 'ar'},
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      final list = response.data['video_types'] as List<dynamic>;
      return list
          .map((e) => VideoType.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching video types: ');
      return [];
    }
  }

  Future<List<ReciterVideos>> fetchVideos() async {
    try {
      final response = await _dio.get(
        'https://mp3quran.net/api/v3/videos',
        queryParameters: {'language': 'ar'},
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      final list = response.data['videos'] as List<dynamic>;
      return list
          .map((e) => ReciterVideos.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching videos: ');
      return [];
    }
  }
}
