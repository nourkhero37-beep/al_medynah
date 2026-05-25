import 'package:al_medynah/features/quran/tafseer/tafseer_bottom_sheet.dart';
import 'package:al_medynah/services/bookmark_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:al_medynah/model/surah_model.dart';
import 'package:al_medynah/services/audio_manager_api.dart';
import 'repository/mushaf_repository.dart';
import 'bloc/mushaf_bloc.dart';
import 'bloc/mushaf_event.dart';
import 'bloc/mushaf_state.dart';

class MushafScreen extends StatelessWidget {
  final int initialPage;
  final String? highlightedVerseKey;
  final VoidCallback? onBookmarkSaved; // ✅ named parameter

  const MushafScreen({
    super.key,
    required this.initialPage,
    this.highlightedVerseKey,
    this.onBookmarkSaved, // ✅ named
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => MushafRepository(),
      child: BlocProvider(
        create: (context) =>
            MushafBloc(repository: context.read<MushafRepository>())..add(
              MushafInitialLoad(
                initialPage: initialPage,
                highlightedVerseKey: highlightedVerseKey,
              ),
            ),
        // ✅ نمرر الـ callback لـ _MushafView
        child: _MushafView(
          initialPage: initialPage,
          onBookmarkSaved: onBookmarkSaved,
        ),
      ),
    );
  }
}

class _MushafView extends StatefulWidget {
  final int initialPage;
  final VoidCallback? onBookmarkSaved; // ✅ named parameter

  const _MushafView({
    this.initialPage = 1,
    this.onBookmarkSaved, // ✅ named
  });

  @override
  State<_MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends State<_MushafView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MushafBloc, MushafState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor:
                  state.errorMessage == 'يجب تحميل القارئ أولاً من صفحة القراء'
                  ? Colors.red
                  : Colors.orange,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff8f3e8),
        bottomNavigationBar: const _AudioPlayerBar(),
        body: SafeArea(
          child: Stack(
            children: [
              // ✅ المصحف
              BlocBuilder<MushafBloc, MushafState>(
                builder: (context, state) {
                  return PageView.builder(
                    controller: _pageController,
                    itemCount: 604,
                    reverse: true,
                    onPageChanged: (index) {
                      final page = index + 1;
                      context.read<MushafBloc>().add(MushafPageChanged(page));
                    },
                    itemBuilder: (context, index) {
                      final page = index + 1;
                      final pageData = state.pagesCache[page];
                      if (pageData == null) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _MushafPageView(
                        page: page,
                        pageData: pageData,
                        selectedVerseKey: state.selectedVerseKey,
                      );
                    },
                  );
                },
              ),

              // ✅ رقم الصفحة
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: BlocBuilder<MushafBloc, MushafState>(
                  builder: (context, state) {
                    return Center(
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
                          '${state.currentPage} / 604',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ✅ زر حفظ الإشارة
              Positioned(
                top: 8,
                right: 12,
                child: BlocBuilder<MushafBloc, MushafState>(
                  builder: (context, state) {
                    return _BookmarkButton(
                      selectedVerseKey: state.selectedVerseKey,
                      currentPage: state.currentPage,
                      // ✅ نمرر الـ callback من widget
                      onBookmarkSaved: widget.onBookmarkSaved,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ زر الإشارة المرجعية
class _BookmarkButton extends StatefulWidget {
  final String? selectedVerseKey;
  final int currentPage;
  final VoidCallback? onBookmarkSaved; // ✅ named parameter

  const _BookmarkButton({
    this.selectedVerseKey,
    required this.currentPage,
    this.onBookmarkSaved, // ✅ named
  });

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton> {
  bool _isSaved = false;

  Future<void> _toggleBookmark() async {
    if (widget.selectedVerseKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اضغط على آية أولاً لحفظها'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final parts = widget.selectedVerseKey!.split(':');
    final surahId = int.tryParse(parts[0]) ?? 1;
    final ayahNumber = int.tryParse(parts[1]) ?? 1;
    final surahName = surahList
        .firstWhere((s) => s.id == surahId, orElse: () => surahList.first)
        .nameArabic;

    await BookmarkService().saveBookmark(
      page: widget.currentPage,
      verseKey: widget.selectedVerseKey!,
      surahName: surahName,
      ayahNumber: ayahNumber,
    );

    // ✅ مصحح: widget.onBookmarkSaved بدل onBookmarkSaved
    widget.onBookmarkSaved?.call();

    setState(() => _isSaved = true);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم حفظ الإشارة — سورة $surahName آية $ayahNumber'),
        backgroundColor: const Color(0xFF8B6914),
        duration: const Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isSaved = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleBookmark,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isSaved
              ? const Color(0xFF8B6914)
              : Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isSaved ? Colors.white : Colors.black54,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              'حفظ',
              style: TextStyle(
                fontSize: 12,
                color: _isSaved ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ مشغل الصوت — بقي كما هو
class _AudioPlayerBar extends StatelessWidget {
  const _AudioPlayerBar();

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MushafBloc, MushafState>(
      buildWhen: (prev, curr) =>
          prev.isPlaying != curr.isPlaying ||
          prev.isPaused != curr.isPaused ||
          prev.selectedVerseKey != curr.selectedVerseKey ||
          prev.currentPosition != curr.currentPosition ||
          prev.totalDuration != curr.totalDuration,
      builder: (context, state) {
        final bool isActive = state.isPlaying || state.isPaused;

        if (!isActive && state.selectedVerseKey == null) {
          return const SizedBox.shrink();
        }

        final position = state.currentPosition;
        final total = state.totalDuration;
        final double progress = (total.inMilliseconds > 0)
            ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        String surahName = '';
        String ayahNumber = '';
        if (state.selectedVerseKey != null) {
          final parts = state.selectedVerseKey!.split(':');
          final surahId = int.tryParse(parts[0]) ?? 0;
          ayahNumber = parts.length > 1 ? parts[1] : '';
          if (surahId >= 1 && surahId <= surahList.length) {
            surahName = surahList[surahId - 1].nameArabic;
          }
        }

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF3E2A0F),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2.5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: const Color(0xFFB8964E),
                      inactiveTrackColor: Colors.white24,
                      thumbColor: const Color(0xFFB8964E),
                      overlayColor: const Color(0x33B8964E),
                    ),
                    child: Slider(
                      value: progress,
                      onChanged: (val) {
                        if (total.inMilliseconds > 0) {
                          final seekMs = (val * total.inMilliseconds).toInt();
                          AudioManager().player.seek(
                            Duration(milliseconds: seekMs),
                          );
                        }
                      },
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          _formatDuration(position),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isActive)
                        GestureDetector(
                          onTap: () => context.read<MushafBloc>().add(
                            const MushafStopTapped(),
                          ),
                          child: const Icon(
                            Icons.stop_rounded,
                            color: Colors.white54,
                            size: 28,
                          ),
                        ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          if (!isActive) {
                            context.read<MushafBloc>().add(
                              const MushafPlayTapped(),
                            );
                          } else {
                            context.read<MushafBloc>().add(
                              const MushafPauseTapped(),
                            );
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB8964E),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            state.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            surahName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (ayahNumber.isNotEmpty)
                            Text(
                              'آية $ayahNumber',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 36,
                        child: Text(
                          _formatDuration(total),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ✅ عرض صفحة المصحف — بقي كما هو
class _MushafPageView extends StatelessWidget {
  final int page;
  final Map<String, dynamic> pageData;
  final String? selectedVerseKey;

  const _MushafPageView({
    required this.page,
    required this.pageData,
    this.selectedVerseKey,
  });

  @override
  Widget build(BuildContext context) {
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
                          onTap: () {
                            context.read<MushafBloc>().add(
                              MushafWordTapped(verseKey),
                            );
                          },
                          onLongPress: () {
                            if (verseKey != null) {
                              TafseerBottomSheet.show(context, verseKey);
                            }
                          },
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
