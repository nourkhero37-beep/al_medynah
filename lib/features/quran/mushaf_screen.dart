import 'dart:async';
import 'dart:convert';
import 'package:al_medynah/services/audio_manager_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MushafScreen extends StatefulWidget {
  final int initialPage;
  final String? highlightedVerseKey;

  const MushafScreen({
    super.key,
    required this.initialPage,
    this.highlightedVerseKey,
  });

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late PageController _pageController;
  final Map<int, Map<String, dynamic>> _pagesCache = {};
  String? selectedVerseKey;
  int currentPage = 1;

  final AudioManager _audioManager = AudioManager();
  bool _isPlaying = false;
  Map<String, List<int>> _verseTimings = {};
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    debugPrint('initState: initialPage=${widget.initialPage}, highlightedVerseKey=${widget.highlightedVerseKey}');
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);

    currentPage = widget.initialPage;
    selectedVerseKey = widget.highlightedVerseKey;
    _preloadPages(widget.initialPage);

    _audioManager.player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    debugPrint('dispose');
    _positionSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _pageNumber(int page) {
    final result = page.toString().padLeft(3, '0');
    debugPrint('_pageNumber: $page -> $result');
    return result;
  }

  Future<void> _loadPage(int page) async {
    debugPrint('_loadPage: page=$page, cached=${_pagesCache.containsKey(page)}');
    if (page < 1 || page > 604) return;
    if (_pagesCache.containsKey(page)) return;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/quran_data/pages/${_pageNumber(page)}.json',
      );
      _pagesCache[page] = jsonDecode(jsonString);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading page $page : $e');
    }
  }

  void _preloadPages(int page) {
    debugPrint('_preloadPages $page');
    _loadPage(page);
    if (page + 1 <= 604) _loadPage(page + 1);
    if (page + 2 <= 604) _loadPage(page + 2);
    if (page - 1 >= 1) _loadPage(page - 1);
  }

  void _onPageChanged(int index) {
    debugPrint('_onPageChanged $index');

    final page = index + 1;
    setState(() {
      currentPage = page;
      debugPrint('setState: currentPage=$page');
      // selectedVerseKey = null;
    });
    _preloadPages(page);
  }

  void _onWordTap(String? verseKey) {
    debugPrint('_onWordTap $verseKey');

    if (verseKey == null) return;
    setState(() {
      selectedVerseKey = selectedVerseKey == verseKey ? null : verseKey;
      debugPrint('setState: selectedVerseKey=${selectedVerseKey ?? "null"} (${selectedVerseKey == verseKey ? "deselect" : "select"})');
    });
  }

  Future<void> _onPlayTap() async {
    debugPrint('_onPlayTap: isPlaying=$_isPlaying, selectedVerseKey=$selectedVerseKey');
    if (selectedVerseKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اضغط على آية أولاً لتشغيلها'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isPlaying) {
      await _audioManager.stop();
      _positionSubscription?.cancel();
      return;
    }

    final surahNumber = int.tryParse(selectedVerseKey!.split(':')[0]) ?? 1;

    final downloaded = await _audioManager.isSurahDownloaded(
      _audioManager.currentReciterId ?? '',
      surahNumber,
    );

    if (!downloaded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب تحميل القارئ أولاً من صفحة القراء'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_audioManager.currentReciterId != null) {
      _verseTimings = await _audioManager.fetchVerseTimings(
        int.tryParse(_audioManager.currentReciterId!) ?? 0,
        surahNumber,
      );
    }

    debugPrint('_onPlayTap: playing verse=$selectedVerseKey, timings loaded=${_verseTimings.length}');
    await _audioManager.playVerse(selectedVerseKey!);

    // ✅ نتتبع الموضع مع debugPrint لنشوف المشكلة
    _positionSubscription?.cancel();
    _positionSubscription = _audioManager.player.positionStream.listen((
      position,
    ) {
      final ms = position.inMilliseconds;

      // ✅ أضفنا debugPrint لنشوف الموضع والآيات
      debugPrint('position: $ms ms | timings count: ${_verseTimings.length}');

      for (final entry in _verseTimings.entries) {
        final start = entry.value[0];
        final end = entry.value[1];
        if (ms >= start && ms < end) {
          // ✅ أضفنا debugPrint لنشوف الآية الحالية
          debugPrint('الآية الحالية: ${entry.key}');
          if (mounted && selectedVerseKey != entry.key) {
            setState(() => selectedVerseKey = entry.key);
          }
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('build: currentPage=$currentPage, selectedVerseKey=$selectedVerseKey');
    return Scaffold(
      backgroundColor: const Color(0xfff8f3e8),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: 604,
              reverse: true,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final page = index + 1;
                final pageData = _pagesCache[page];
                if (pageData == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildPage(page, pageData);
              },
            ),

            // رقم الصفحة
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$currentPage / 604',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ),
            ),

            // زر التشغيل
            Positioned(
              bottom: 40,
              left: 16,
              child: GestureDetector(
                onTap: _onPlayTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _isPlaying
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF8B6914),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int page, Map<String, dynamic> pageData) {
    debugPrint('_buildPage: page=$page, lines count=${(pageData['lines'] as List?)?.length ?? 0}');
    final lines = pageData['lines'] as List<dynamic>? ?? [];
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSpecialPage = page == 1 || page == 2;

    return SizedBox(
      width: double.infinity,
      height: screenHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisAlignment: isSpecialPage
              ? MainAxisAlignment.start
              : MainAxisAlignment.spaceEvenly,
          children: [
            if (isSpecialPage) SizedBox(height: screenHeight * 0.025),
            ...lines.map<Widget>((line) {
              final words = line['words'] as List<dynamic>? ?? [];
              if (words.isEmpty) return const SizedBox();

              return Padding(
                padding: EdgeInsets.symmetric(vertical: isSpecialPage ? 1 : 0),
                child: SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      textDirection: TextDirection.rtl,
                      children: words.map<Widget>((word) {
                        final String char = word['char'] ?? '';
                        final String font = word['font'] ?? 'QCF4_Hafs_01';
                        final String type = word['type'] ?? 'word';
                        final String? verseKey = word['verse_key'];

                        if (char.isEmpty) return const SizedBox();

                        if (type == 'surah_header') {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/images/surah_header_frames.png',
                                width: screenWidth * 1.20,
                                height: screenHeight * 0.06,
                                fit: BoxFit.contain,
                              ),
                              Text(
                                char,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: font,
                                  fontSize: screenHeight * 0.033,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          );
                        }

                        final bool isHighlighted =
                            verseKey != null && verseKey == selectedVerseKey;

                        return GestureDetector(
                          onTap: () => _onWordTap(verseKey),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? const Color(0xFFB8D4A8).withOpacity(0.6)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              char,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: isSpecialPage
                                    ? screenHeight * 0.024
                                    : screenHeight * 0.022,
                                color: isHighlighted
                                    ? const Color(0xFF2E7D32)
                                    : Colors.black87,
                                height: isSpecialPage ? 3 : 1.9,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
