import 'package:flutter_tts/flutter_tts.dart';

class TafseerTtsManager {
  final FlutterTts _tts = FlutterTts();
  bool isSpeaking = false;
  bool isPaused = false;

  final void Function()? onStateChanged;

  TafseerTtsManager({this.onStateChanged});

  Future<void> init() async {
    await _tts.setLanguage('ar-SA');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    final voices = await _tts.getVoices as List?;
    if (voices != null) {
      final arabicMale = voices.firstWhere((v) {
        final name = (v['name'] as String? ?? '').toLowerCase();
        final locale = (v['locale'] as String? ?? '').toLowerCase();
        final gender = (v['gender'] as String? ?? '').toLowerCase();
        return locale.contains('ar') &&
            (gender.contains('male') || name.contains('male'));
      }, orElse: () => null);

      if (arabicMale != null) {
        await _tts.setVoice({
          'name': arabicMale['name'],
          'locale': arabicMale['locale'],
        });
        return;
      }

      final anyArabic = voices.firstWhere((v) {
        final locale = (v['locale'] as String? ?? '').toLowerCase();
        return locale.contains('ar');
      }, orElse: () => null);

      if (anyArabic != null) {
        await _tts.setVoice({
          'name': anyArabic['name'],
          'locale': anyArabic['locale'],
        });
        return;
      }
    }

    await _tts.setLanguage('ar-SA');

    _tts.setStartHandler(() {
      isSpeaking = true;
      onStateChanged?.call();
    });
    _tts.setCompletionHandler(() {
      isSpeaking = false;
      isPaused = false;
      onStateChanged?.call();
    });
    _tts.setCancelHandler(() {
      isSpeaking = false;
      isPaused = false;
      onStateChanged?.call();
    });
    _tts.setPauseHandler(() {
      isPaused = true;
      onStateChanged?.call();
    });
    _tts.setContinueHandler(() {
      isPaused = false;
      onStateChanged?.call();
    });
  }

  static String cleanText(String text) {
    return text
        .replaceAll(RegExp(r'[^\u0600-\u06FF\u0750-\u077F\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> toggleSpeech(String? text) async {
    if (text == null) return;
    if (isSpeaking && !isPaused) {
      await _tts.pause();
    } else {
      await _tts.speak(cleanText(text));
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    isSpeaking = false;
    isPaused = false;
    onStateChanged?.call();
  }

  void dispose() {
    _tts.stop();
  }
}
