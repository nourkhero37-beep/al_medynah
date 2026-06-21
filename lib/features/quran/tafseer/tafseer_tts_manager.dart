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
      final arabicMaleVoice = voices.firstWhere((v) {
        final name = (v['name'] as String? ?? '').toLowerCase();
        final locale = (v['locale'] as String? ?? '').toLowerCase();
        final gender = (v['gender'] as String? ?? '').toLowerCase();
        return (locale.contains('ar')) &&
            (gender.contains('male') || name.contains('male'));
      }, orElse: () => null);

      if (arabicMaleVoice != null) {
        await _tts.setVoice({
          'name': arabicMaleVoice['name'],
          'locale': arabicMaleVoice['locale'],
        });
      } else {
        await _tts.setPitch(0.75);
      }
    }

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

  Future<void> toggleSpeech(String? text) async {
    if (text == null) return;
    if (isSpeaking && !isPaused) {
      await _tts.pause();
    } else {
      await _tts.speak(text);
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
