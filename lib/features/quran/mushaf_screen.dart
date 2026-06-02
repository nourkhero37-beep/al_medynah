import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:al_medynah/features/quran/tafseer/tafseer_bottom_sheet.dart';
import 'package:al_medynah/services/bookmark_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:al_medynah/model/surah_model.dart';
import 'package:al_medynah/services/audio_manager_api.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'repository/mushaf_repository.dart';
import 'bloc/mushaf_bloc.dart';
import 'bloc/mushaf_event.dart';
import 'bloc/mushaf_state.dart';
import 'package:al_medynah/l10n/app_localizations.dart';

class MushafScreen extends StatelessWidget {
  final int initialPage;
  final String? highlightedVerseKey;
  final VoidCallback? onBookmarkSaved;

  const MushafScreen({
    super.key,
    required this.initialPage,
    this.highlightedVerseKey,
    this.onBookmarkSaved,
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
  final VoidCallback? onBookmarkSaved;

  const _MushafView({
    this.initialPage = 1,
    this.onBookmarkSaved,
  });

  @override
  State<_MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends State<_MushafView> {
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _pageCaptureKey = GlobalKey();
  Map<String, int> _verseToPage = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _loadVersePageMap();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadVersePageMap() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/quran_data/verses.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final map = <String, int>{};
      data.forEach((key, value) {
        map[key] = (value as Map<String, dynamic>)['page'] as int;
      });
      _verseToPage = map;
    } catch (_) {}
  }

  void _goToPage(BuildContext context) {
    final tr = AppLocalizations.of(context).tr;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(tr('mushaf.menu.goToPage')),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: tr('mushaf.menu.jumpHint'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('mushaf.menu.cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final page = int.tryParse(controller.text);
                if (page != null && page >= 1 && page <= 604) {
                  Navigator.pop(ctx);
                  _pageController.jumpToPage(page - 1);
                }
              },
              child: Text(tr('mushaf.menu.jumpGo')),
            ),
          ],
        ),
      ),
    );
  }

  void _showSavedPage(BuildContext context, int? savedPage) {
    final tr = AppLocalizations.of(context).tr;
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(tr('mushaf.menu.bookmarks')),
          content: savedPage != null
              ? Text(tr('mushaf.menu.bookmarkedPage', {'page': savedPage.toString()}))
              : Text(tr('mushaf.menu.noBookmark')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('mushaf.menu.ok')),
            ),
            if (savedPage != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _pageController.jumpToPage(savedPage - 1);
                  context.read<MushafBloc>().add(MushafPageChanged(savedPage));
                },
                child: Text(tr('mushaf.menu.jumpGo')),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sharePage(BuildContext context, int page) async {
    final tr = AppLocalizations.of(context).tr;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await WidgetsBinding.instance.endOfFrame;
    final boundary = _pageCaptureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      await Share.share(tr('mushaf.menu.shared', {'page': page.toString()}));
      return;
    }
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        await Share.share(tr('mushaf.menu.shared', {'page': page.toString()}));
        return;
      }
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/quran_page_$page.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: tr('mushaf.menu.shared', {'page': page.toString()}),
      );
    } catch (_) {
      await Share.share(tr('mushaf.menu.shared', {'page': page.toString()}));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MushafBloc, MushafState>(
      listenWhen: (prev, curr) =>
        prev.selectedVerseKey != curr.selectedVerseKey ||
        prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          final tr = AppLocalizations.of(context).tr;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(state.errorMessage!)),
              backgroundColor:
                  state.errorMessage == 'mushaf.error.noReciter'
                  ? Colors.red
                  : Colors.orange,
            ),
          );
        }
        if (state.isPlaying && state.selectedVerseKey != null) {
          final page = _verseToPage[state.selectedVerseKey];
          if (page != null && page != state.currentPage) {
            _pageController.jumpToPage(page - 1);
          }
        }
      },
      child: BlocBuilder<MushafBloc, MushafState>(
        buildWhen: (p, c) => p.isDarkMode != c.isDarkMode,
        builder: (ctx, st) => Scaffold(
          key: _scaffoldKey,
          backgroundColor: st.isDarkMode ? Colors.black : const Color(0xfff8f3e8),
        drawer: _MushafDrawer(
          onBookmarkSaved: widget.onBookmarkSaved,
          scaffoldKey: _scaffoldKey,
          onGoToPage: () => _goToPage(context),
          onShowSavedPage: (page) => _showSavedPage(context, page),
          onSharePage: (page) => _sharePage(context, page),
        ),
        bottomNavigationBar: const _AudioPlayerBar(),
        body: SafeArea(
          child: Stack(
            children: [
              BlocBuilder<MushafBloc, MushafState>(
                builder: (context, state) {
                  return Directionality(
                    textDirection: TextDirection.rtl,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: 604,
                      pageSnapping: true,
                      physics: const PageScrollPhysics(),
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
                        return RepaintBoundary(
                          key: page == state.currentPage ? _pageCaptureKey : null,
                          child: _MushafPageView(
                            page: page,
                            pageData: pageData,
                            selectedVerseKey: state.selectedVerseKey,
                            fontScale: state.fontScale,
                            isDarkMode: state.isDarkMode,
                            textColor: state.textColor,
                          ),
                        );
                      },
                    ),
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
                          color: (state.isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${state.currentPage} / 604',
                          style: TextStyle(
                            fontSize: 12,
                            color: state.isDarkMode ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                top: 8,
                right: 12,
                child: GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (st.isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      color: (st.isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
class _MushafDrawer extends StatelessWidget {
  final VoidCallback? onBookmarkSaved;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onGoToPage;
  final void Function(int?) onShowSavedPage;
  final void Function(int) onSharePage;

  const _MushafDrawer({
    this.onBookmarkSaved,
    required this.scaffoldKey,
    required this.onGoToPage,
    required this.onShowSavedPage,
    required this.onSharePage,
  });

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context).tr;
    return BlocBuilder<MushafBloc, MushafState>(
      builder: (context, state) {
        return Drawer(
          child: Container(
            color: const Color(0xFF3E2A0F),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFB8964E),
                    ),
                    child: Text(
                      '${tr('mushaf.menu.goToPage')} ${state.currentPage} / 604',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _drawerItem(
                          icon: Icons.bookmark_add_rounded,
                          text: tr('mushaf.menu.savePage'),
                          onTap: () async {
                            await BookmarkService().savePageBookmark(state.currentPage);
                            onBookmarkSaved?.call();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr('mushaf.bookmark.pageSaved', {
                                  'page': state.currentPage.toString(),
                                })),
                                backgroundColor: const Color(0xFF8B6914),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            scaffoldKey.currentState?.closeDrawer();
                          },
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        _drawerItem(
                          icon: Icons.numbers,
                          text: tr('mushaf.menu.goToPage'),
                          onTap: () {
                            scaffoldKey.currentState?.closeDrawer();
                            onGoToPage();
                          },
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        _drawerItem(
                          icon: Icons.bookmark_border_rounded,
                          text: tr('mushaf.menu.bookmarks'),
                          onTap: () async {
                            scaffoldKey.currentState?.closeDrawer();
                            final savedPage = await BookmarkService().getPageBookmark();
                            if (context.mounted) onShowSavedPage(savedPage);
                          },
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        _drawerItem(
                          icon: Icons.share_rounded,
                          text: tr('mushaf.menu.share'),
                          onTap: () {
                            scaffoldKey.currentState?.closeDrawer();
                            onSharePage(state.currentPage);
                          },
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        _drawerItem(
                          icon: Icons.text_increase_rounded,
                          text: tr('mushaf.menu.fontIncrease'),
                          onTap: () {
                            scaffoldKey.currentState?.closeDrawer();
                            final newScale = (state.fontScale + 0.1).clamp(0.5, 2.0);
                            context.read<MushafBloc>().add(
                              MushafFontSizeChanged(newScale),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr('mushaf.menu.fontSizeChanged', {
                                  'size': (newScale * 100).toInt().toString(),
                                })),
                                backgroundColor: const Color(0xFF8B6914),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        _drawerItem(
                          icon: Icons.text_decrease_rounded,
                          text: tr('mushaf.menu.fontDecrease'),
                          onTap: () {
                            scaffoldKey.currentState?.closeDrawer();
                            final newScale = (state.fontScale - 0.1).clamp(0.5, 2.0);
                            context.read<MushafBloc>().add(
                              MushafFontSizeChanged(newScale),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr('mushaf.menu.fontSizeChanged', {
                                  'size': (newScale * 100).toInt().toString(),
                                })),
                                backgroundColor: const Color(0xFF8B6914),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        _drawerItem(
                          icon: Icons.format_size_rounded,
                          text: tr('mushaf.menu.fontReset'),
                          onTap: () {
                            scaffoldKey.currentState?.closeDrawer();
                            context.read<MushafBloc>().add(
                              const MushafFontSizeChanged(1.0),
                            );
                          },
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        _drawerItem(
                          icon: state.isDarkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          text: tr('mushaf.menu.darkMode'),
                          trailing: state.isDarkMode
                              ? const Icon(Icons.check, color: Color(0xFFB8964E), size: 20)
                              : null,
                          onTap: () {
                            scaffoldKey.currentState?.closeDrawer();
                            final newMode = !state.isDarkMode;
                            context.read<MushafBloc>().add(
                              MushafDarkModeToggled(newMode),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr(newMode ? 'mushaf.menu.darkModeOn' : 'mushaf.menu.darkModeOff')),
                                backgroundColor: const Color(0xFF8B6914),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        _drawerItem(
                          icon: Icons.settings_rounded,
                          text: tr('mushaf.menu.settings'),
                          onTap: () {
                            scaffoldKey.currentState?.closeDrawer();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr('mushaf.menu.settings')),
                                backgroundColor: const Color(0xFF8B6914),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String text,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFB8964E), size: 22),
      title: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      dense: true,
    );
  }
}


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
        final bool show = isActive || state.selectedVerseKey != null;

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

        return AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: Container(
            height: show ? null : 0,
            clipBehavior: Clip.hardEdge,
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
                                '\u0622\u06CC\u0629 $ayahNumber',
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
            ),
        );
      },
    );
  }
}

class _MushafPageView extends StatelessWidget {
  final int page;
  final Map<String, dynamic> pageData;
  final String? selectedVerseKey;
  final double fontScale;
  final bool isDarkMode;
  final int textColor;

  const _MushafPageView({
    required this.page,
    required this.pageData,
    this.selectedVerseKey,
    this.fontScale = 1.0,
    this.isDarkMode = false,
    this.textColor = 0xDD000000,
  });

  static const List<int> _colorOptions = [
    0xFF000000,
    0xFFFFFFFF,
    0xFFB8964E,
    0xFF3E2A0F,
    0xFF2E5090,
    0xFF2E7D32,
    0xFF8B6914,
    0xFF555555,
  ];

  static Future<void> _showColorPicker(BuildContext context) {
    final tr = AppLocalizations.of(context).tr;
    return showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(tr('mushaf.colorPicker.title')),
          content: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _colorOptions.map((c) {
              final isWhite = c == 0xFFFFFFFF;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<MushafBloc>().add(
                    MushafTextColorChanged(c),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isWhite ? Colors.grey.shade400 : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('mushaf.menu.cancel')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = pageData['lines'] as List<dynamic>? ?? [];
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSpecialPage = page == 1 || page == 2;

    return SizedBox(
      width: double.infinity,
      height: screenHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: isDarkMode ? Colors.black : const Color(0xfff8f3e8),
            ),
          ),
          Padding(
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
                                      fontSize: screenHeight * 0.033 * fontScale,
                                      color: Color(textColor),
                                    ),
                                  ),
                                ],
                              );
                            }

                            final bool isHighlighted =
                                verseKey != null && verseKey == selectedVerseKey;

                            Offset? longPressPos;

                            return GestureDetector(
                              onTap: () {
                                context.read<MushafBloc>().add(
                                  MushafWordTapped(verseKey),
                                );
                              },
                              onLongPressStart: (details) {
                                longPressPos = details.globalPosition;
                              },
                              onLongPress: () {
                                if (verseKey == null || longPressPos == null) return;
                                final pos = longPressPos!;
                                final tr = AppLocalizations.of(context).tr;
                                showMenu<String>(
                                  context: context,
                                  position: RelativeRect.fromLTRB(
                                    pos.dx, pos.dy, pos.dx, pos.dy,
                                  ),
                                  items: [
                                    PopupMenuItem(
                                      value: 'tafseer',
                                      child: Text(tr('mushaf.longpress.tafseer')),
                                    ),
                                    PopupMenuItem(
                                      value: 'play',
                                      child: Text(tr('mushaf.longpress.play')),
                                    ),
                                    PopupMenuItem(
                                      value: 'color',
                                      child: Text(tr('mushaf.longpress.changeColor')),
                                    ),
                                  ],
                                ).then((value) {
                                  if (value == null) return;
                                  if (!context.mounted) return;
                                  switch (value) {
                                    case 'tafseer':
                                      TafseerBottomSheet.show(context, verseKey);
                                    case 'play':
                                      context.read<MushafBloc>().add(
                                        MushafWordTapped(verseKey),
                                      );
                                      context.read<MushafBloc>().add(
                                        const MushafPlayTapped(),
                                      );
                                    case 'color':
                                      _showColorPicker(context);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isHighlighted
                                      ? const Color(0xFFB8D4A8).withValues(alpha: 0.6)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  char,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontFamily: font,
                                    fontSize: (isSpecialPage
                                            ? screenHeight * 0.024
                                            : screenHeight * 0.022) *
                                        fontScale,
                                    color: isHighlighted
                                        ? const Color(0xFF2E7D32)
                                        : Color(textColor),
                                    height: (isSpecialPage ? 3 : 1.9) / fontScale.clamp(0.7, 1.3),
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
        ],
      ),
    );
  }
}

