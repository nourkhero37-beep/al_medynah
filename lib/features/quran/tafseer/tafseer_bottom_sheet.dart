import 'package:al_medynah/l10n/app_localizations.dart';
// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:al_medynah/features/quran/tafseer/tafseer_service.dart';
import 'package:flutter/material.dart';
import 'package:al_medynah/features/quran/tafseer/tafseer_tts_manager.dart';
import 'package:al_medynah/model/surah_model.dart';
import 'package:al_medynah/main.dart';

class TafseerBottomSheet extends StatefulWidget {
  final String verseKey;

  const TafseerBottomSheet({super.key, required this.verseKey});

  static void show(BuildContext context, String verseKey) {
    final screenHeight = MediaQuery.of(context).size.height;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      backgroundColor: Colors.transparent,
      builder: (_) => TafseerBottomSheet(verseKey: verseKey),
    );
  }

  @override
  State<TafseerBottomSheet> createState() => _TafseerBottomSheetState();
}

class _TafseerBottomSheetState extends State<TafseerBottomSheet> {
  static const Color tealColor = Color(0xFF2493B4);
  static const Color darkBrown = Color(0xFF3E2A0F);

  String? _tafseerText;
  bool _isLoading = true;
  bool _hasError = false;

  late String _currentVerseKey;
  late int _currentSurahId;
  late int _currentAyahNumber;

  late final TafseerTtsManager _ttsManager;

  @override
  void initState() {
    super.initState();
    _currentVerseKey = widget.verseKey;
    _parseVerseKey(_currentVerseKey);
    _ttsManager = TafseerTtsManager(onStateChanged: () { if (mounted) setState(() {}); })..init();
    _loadTafseer();
  }

  void _parseVerseKey(String verseKey) {
    final parts = verseKey.split(':');
    _currentSurahId = int.tryParse(parts[0]) ?? 1;
    _currentAyahNumber = int.tryParse(parts[1]) ?? 1;
  }

  Future<void> _loadTafseer() async {
    await _ttsManager.stop();

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
    _ttsManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appDarkModeNotifier.value;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF2493B4),
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
                    Text(
                      AppLocalizations.of(context).tr('tafseer.header.title'),
                      style: const TextStyle(
                        fontFamily: 'GE SS Two',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\u0633\u0648\u0631\u0629 $_surahName \u2014 \u0622\u064A\u0629 $_currentAyahNumber',
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
          Flexible(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2493B4),
                      ),
                    ),
                  )
                : _hasError
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context).tr('tafseer.error.load'),
                          style: TextStyle(color: isDark ? Colors.white70 : darkBrown, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2493B4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _loadTafseer,
                          child: Text(AppLocalizations.of(context).tr('tafseer.retry')),
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: tealColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: tealColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _ttsManager.toggleSpeech(_tafseerText),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: _ttsManager.isSpeaking
                                          ? const Color(0xFF2493B4)
                                          : const Color(0xFF2493B4)
                                              .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _ttsManager.isSpeaking && !_ttsManager.isPaused
                                          ? Icons.pause_rounded
                                          : Icons.volume_up_rounded,
                                      color: _ttsManager.isSpeaking
                                          ? Colors.white
                                          : const Color(0xFF2493B4),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '\u0633\u0648\u0631\u0629 $_surahName \u2014 \u0627\u0644\u0622\u064A\u0629 $_currentAyahNumber',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'GE SS Two',
                                    fontSize: 13,
                                    color: Color(0xFF1E7FA0),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.format_quote_rounded,
                                color: Color(0xFF2493B4),
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.of(context).tr('tafseer.section.tafsir'),
                                style: const TextStyle(
                                  fontFamily: 'GE SS Two',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2493B4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _tafseerText ?? '',
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.white70 : darkBrown,
                              height: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              border: Border(
                top: BorderSide(color: tealColor.withValues(alpha: 0.2), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _hasPrevious ? _goToPrevious : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _hasPrevious
                            ? const Color(0xFF2493B4)
                            : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 16,
                            color: _hasPrevious ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context).tr('tafseer.button.prev'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _hasPrevious ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tealColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: tealColor.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(
                      '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF4DD0E1) : const Color(0xFF2493B4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _hasNext ? _goToNext : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _hasNext
                            ? const Color(0xFF2493B4)
                            : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context).tr('tafseer.button.next'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _hasNext ? Colors.white : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: _hasNext ? Colors.white : Colors.grey,
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








