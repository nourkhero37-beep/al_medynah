// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:al_medynah/features/quran/tafseer/tafseer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:al_medynah/model/surah_model.dart';

class TafseerBottomSheet extends StatefulWidget {
  final String verseKey;

  const TafseerBottomSheet({super.key, required this.verseKey});

  static void show(BuildContext context, String verseKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TafseerBottomSheet(verseKey: verseKey),
    );
  }

  @override
  State<TafseerBottomSheet> createState() => _TafseerBottomSheetState();
}

class _TafseerBottomSheetState extends State<TafseerBottomSheet> {
  static const Color goldColor = Color(0xFFB8964E);
  static const Color darkBrown = Color(0xFF3E2A0F);

  String? _tafseerText;
  bool _isLoading = true;
  bool _hasError = false;

  late String _currentVerseKey;
  late int _currentSurahId;
  late int _currentAyahNumber;

  // ✅ TTS
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentVerseKey = widget.verseKey;
    _parseVerseKey(_currentVerseKey);
    _initTts();
    _loadTafseer();
  }

  // ✅ إعداد الـ TTS بالعربي
  Future<void> _initTts() async {
    await _tts.setLanguage('ar-SA');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // ✅ نجيب كل الأصوات المتاحة ونختار ذكر عربي
    final voices = await _tts.getVoices as List?;
    if (voices != null) {
      debugPrint('Available voices: $voices');

      // ✅ نفلتر على العربي والذكر
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
        debugPrint('✅ Selected voice: ${arabicMaleVoice['name']}');
      } else {
        // ✅ لو ما لقينا ذكر، نخفض الـ pitch يصير أثقل
        debugPrint('⚠️ No male Arabic voice found, lowering pitch');
        await _tts.setPitch(0.75);
      }
    }

    _tts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted)
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
        });
    });
    _tts.setCancelHandler(() {
      if (mounted)
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
        });
    });
    _tts.setPauseHandler(() {
      if (mounted) setState(() => _isPaused = true);
    });
    _tts.setContinueHandler(() {
      if (mounted) setState(() => _isPaused = false);
    });
  }

  void _parseVerseKey(String verseKey) {
    final parts = verseKey.split(':');
    _currentSurahId = int.tryParse(parts[0]) ?? 1;
    _currentAyahNumber = int.tryParse(parts[1]) ?? 1;
  }

  Future<void> _loadTafseer() async {
    // ✅ نوقف الصوت لما ننتقل لآية جديدة
    await _stopSpeaking();

    setState(() {
      _isLoading = true;
      _hasError = false;
      _tafseerText = null;
    });

    final text = await TafseerService().fetchTafseer(_currentVerseKey);
    if (!mounted) return;

    setState(() {
      _tafseerText = text;
      _isLoading = false;
      _hasError = text == null;
    });
  }

  // ✅ تشغيل / إيقاف مؤقت / استئناف
  Future<void> _toggleSpeech() async {
    if (_tafseerText == null) return;

    if (_isSpeaking && !_isPaused) {
      // إيقاف مؤقت
      await _tts.pause();
    } else if (_isPaused) {
      // استئناف
      await _tts.speak(_tafseerText!);
    } else {
      // بداية التشغيل
      await _tts.speak(_tafseerText!);
    }
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
      });
    }
  }

  void _goToPrevious() {
    if (_currentAyahNumber <= 1) return;
    setState(() {
      _currentAyahNumber--;
      _currentVerseKey = '$_currentSurahId:$_currentAyahNumber';
    });
    _loadTafseer();
  }

  void _goToNext() {
    final surah = surahList.firstWhere(
      (s) => s.id == _currentSurahId,
      orElse: () => surahList.first,
    );
    if (_currentAyahNumber >= surah.versesCount) return;
    setState(() {
      _currentAyahNumber++;
      _currentVerseKey = '$_currentSurahId:$_currentAyahNumber';
    });
    _loadTafseer();
  }

  bool get _hasPrevious => _currentAyahNumber > 1;

  bool get _hasNext {
    final surah = surahList.firstWhere(
      (s) => s.id == _currentSurahId,
      orElse: () => surahList.first,
    );
    return _currentAyahNumber < surah.versesCount;
  }

  String get _surahName {
    final surah = surahList.firstWhere(
      (s) => s.id == _currentSurahId,
      orElse: () => surahList.first,
    );
    return surah.nameArabic;
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      decoration: const BoxDecoration(
        color: Color(0xFFF5ECD7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.brown.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ✅ Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF8B6914),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'تفسير الميسر',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'سورة $_surahName — آية $_currentAyahNumber',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
              ],
            ),
          ),

          // ✅ المحتوى
          Flexible(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B6914),
                      ),
                    ),
                  )
                : _hasError
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'تعذر تحميل التفسير',
                          style: TextStyle(color: darkBrown, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B6914),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _loadTafseer,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : Directionality(
                    textDirection: TextDirection.rtl,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ badge السورة والآية + زر TTS
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: goldColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: goldColor.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                // ✅ زر الصوت
                                GestureDetector(
                                  onTap: _toggleSpeech,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: _isSpeaking
                                          ? const Color(0xFF8B6914)
                                          : const Color(
                                              0xFF8B6914,
                                            ).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isSpeaking && !_isPaused
                                          ? Icons.pause_rounded
                                          : Icons.volume_up_rounded,
                                      color: _isSpeaking
                                          ? Colors.white
                                          : const Color(0xFF8B6914),
                                      size: 20,
                                    ),
                                  ),
                                ),

                                const Spacer(),

                                Text(
                                  'سورة $_surahName — الآية $_currentAyahNumber',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: darkBrown,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          const Row(
                            children: [
                              Icon(
                                Icons.format_quote_rounded,
                                color: Color(0xFF8B6914),
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'التفسير',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B6914),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Text(
                            _tafseerText ?? '',
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              fontSize: 15,
                              color: darkBrown,
                              height: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // ✅ زرا التنقل بالأسفل
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF5ECD7),
              border: Border(
                top: BorderSide(color: goldColor.withOpacity(0.2), width: 1),
              ),
            ),
            child: Row(
              children: [
                // ✅ زر الآية التالية
                Expanded(
                  child: GestureDetector(
                    onTap: _hasNext ? _goToNext : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _hasNext
                            ? const Color(0xFF8B6914)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 16,
                            color: _hasNext ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'التالية',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _hasNext ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // ✅ رقم الآية الحالية
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: goldColor.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      '$_currentAyahNumber',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: darkBrown,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // ✅ زر الآية السابقة
                Expanded(
                  child: GestureDetector(
                    onTap: _hasPrevious ? _goToPrevious : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _hasPrevious
                            ? const Color(0xFF8B6914)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'السابقة',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _hasPrevious ? Colors.white : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: _hasPrevious ? Colors.white : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
