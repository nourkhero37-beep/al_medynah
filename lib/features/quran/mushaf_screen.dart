import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'repository/mushaf_repository.dart';
import 'bloc/mushaf_bloc.dart';
import 'bloc/mushaf_event.dart';
import 'bloc/mushaf_state.dart';

class MushafScreen extends StatelessWidget {
  final int initialPage;
  final String? highlightedVerseKey;

  const MushafScreen({
    super.key,
    required this.initialPage,
    this.highlightedVerseKey,
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
        child: _MushafView(initialPage: initialPage),
      ),
    );
  }
}

class _MushafView extends StatefulWidget {
  final int initialPage;

  const _MushafView({this.initialPage = 1});

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
        body: SafeArea(
          child: Stack(
            children: [
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
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Builder(
                  builder: (context) {
                    return BlocBuilder<MushafBloc, MushafState>(
                      builder: (context, state) {
                        debugPrint('=== isPlaying: ${state.isPlaying} ===');
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                debugPrint('=== Play button tapped ===');
                                context.read<MushafBloc>().add(
                                  const MushafPlayTapped(),
                                );
                              },
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: state.isPlaying
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFF8B6914),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  state.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                            if (state.isPlaying) ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  context.read<MushafBloc>().add(
                                    const MushafStopTapped(),
                                  );
                                },
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB71C1C),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.stop_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
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
