import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../../../model/quran_page_model.dart';
import '../../../services/audio_manager_api.dart';
import '../../../services/quran_data_service.dart';

class MushafRepository {
  final AudioManager _audioManager = AudioManager();
  final Map<int, QuranPage> _pagesCache = {};
  StreamSubscription<Duration>? _positionSubscription;

  Map<int, QuranPage> get pagesCache => Map<int, QuranPage>.from(_pagesCache);

  Future<QuranPage> loadPage(int page) async {
    if (page < 1 || page > 604) {
      throw ArgumentError('Page must be between 1 and 604');
    }
    if (_pagesCache.containsKey(page)) return _pagesCache[page]!;
    final pageData = await QuranDataService().loadPage(page);
    _pagesCache[page] = QuranPage.fromJson(pageData);
    return _pagesCache[page]!;
  }

  Future<void> preloadPages(int page) async {
    final pages = [page, page + 1, page - 1]
      .where((p) => p >= 1 && p <= 604 && !_pagesCache.containsKey(p));
    for (final p in pages) {
      try { await loadPage(p); } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<bool> isSurahDownloaded(int surahNumber) async {
    return _audioManager.isSurahDownloaded(
      _audioManager.currentReciterId ?? '',
      surahNumber,
    );
  }

  Future<Map<String, dynamic>> fetchVerseTimings(int surahNumber) async {
    final reciterId = _audioManager.currentReciterId;
    if (reciterId == null) {
      return {'timings': <String, List<int>>{}, 'duration': 0};
    }
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

  Future<void> pauseAudio() async {
    await _audioManager.player.pause();
  }

  Future<void> resumeAudio() async {
    await _audioManager.player.play();
  }

  Stream<PlayerState> get playerStateStream =>
      _audioManager.player.playerStateStream;

  Duration get currentPosition => _audioManager.player.position;

  Stream<Duration> get positionStream => _audioManager.player.positionStream;

  Stream<Duration?> get durationStream => _audioManager.player.durationStream;

  void cancelPositionSubscription() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    _positionSubscription?.cancel();
  }
}
