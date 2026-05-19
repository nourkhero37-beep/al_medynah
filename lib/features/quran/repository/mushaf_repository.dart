import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../../../services/audio_manager_api.dart';

class MushafRepository {
  final AudioManager _audioManager = AudioManager();
  final Map<int, Map<String, dynamic>> _pagesCache = {};
  StreamSubscription<Duration>? _positionSubscription;

  Map<int, Map<String, dynamic>> get pagesCache => _pagesCache;

  Future<Map<String, dynamic>> loadPage(int page) async {
    if (page < 1 || page > 604) {
      throw ArgumentError('Page must be between 1 and 604');
    }
    if (_pagesCache.containsKey(page)) {
      return _pagesCache[page]!;
    }
    final jsonString = await rootBundle.loadString(
      'assets/quran_data/pages/${page.toString().padLeft(3, '0')}.json',
    );
    final pageData = jsonDecode(jsonString) as Map<String, dynamic>;
    _pagesCache[page] = pageData;
    return pageData;
  }

  Future<void> preloadPages(int page) async {
    final pagesToLoad = <int>[];
    if (page >= 1 && page <= 604) pagesToLoad.add(page);
    if (page + 1 >= 1 && page + 1 <= 604) pagesToLoad.add(page + 1);
    if (page + 2 >= 1 && page + 2 <= 604) pagesToLoad.add(page + 2);
    if (page - 1 >= 1 && page - 1 <= 604) pagesToLoad.add(page - 1);

    for (final p in pagesToLoad) {
      if (!_pagesCache.containsKey(p)) {
        try {
          await loadPage(p);
        } catch (e) {
          // Ignore errors for preloading
        }
      }
    }
  }

  Future<bool> isSurahDownloaded(int surahNumber) async {
    return _audioManager.isSurahDownloaded(
      _audioManager.currentReciterId ?? '',
      surahNumber,
    );
  }

  Future<Map<String, List<int>>> fetchVerseTimings(int surahNumber) async {
    final reciterId = _audioManager.currentReciterId;
    if (reciterId == null) return {};
    return _audioManager.fetchVerseTimings(
      int.tryParse(reciterId) ?? 0,
      surahNumber,
    );
  }

  Future<void> playVerse(String verseKey, {int? seekToMs}) async {
    await _audioManager.playVerse(verseKey, seekToMs: seekToMs);
  }

  Future<void> stopAudio() async {
    await _audioManager.stop();
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Stream<PlayerState> get playerStateStream =>
      _audioManager.player.playerStateStream;

  Stream<Duration> get positionStream => _audioManager.player.positionStream;

  void cancelPositionSubscription() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    _positionSubscription?.cancel();
  }
}
