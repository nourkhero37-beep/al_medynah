import 'mushaf_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'mushaf_page_view.dart';
import 'audio_player_bar.dart';
import 'mushaf_drawer.dart';
import 'repository/mushaf_repository.dart';
import 'bloc/mushaf_bloc.dart';
import 'bloc/mushaf_event.dart';
import 'bloc/mushaf_state.dart';
import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:al_medynah/main.dart';

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

  const _MushafView({this.initialPage = 1, this.onBookmarkSaved});

  @override
  State<_MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends State<_MushafView> {
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _pageCaptureKey = GlobalKey();
  Map<String, int> _verseToPage = {};
  void Function()? _darkModeListener;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _loadVersePageMap();
    _darkModeListener = () {
      if (mounted) {
        context.read<MushafBloc>().add(
          MushafDarkModeToggled(appDarkModeNotifier.value),
        );
      }
    };
    appDarkModeNotifier.addListener(_darkModeListener!);
    context.read<MushafBloc>().add(MushafDarkModeToggled(appDarkModeNotifier.value));
  }


  @override
  void dispose() {
    if (_darkModeListener != null) {
      appDarkModeNotifier.removeListener(_darkModeListener!);
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadVersePageMap() async {
    _verseToPage = await MushafUtils.loadVersePageMap();
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
            decoration: InputDecoration(hintText: tr('mushaf.menu.jumpHint')),
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
              ? Text(
                  tr('mushaf.menu.bookmarkedPage', {
                    'page': savedPage.toString(),
                  }),
                )
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
    await MushafUtils.sharePage(
      pageCaptureKey: _pageCaptureKey,
      page: page,
      text: tr('mushaf.menu.shared', {'page': page.toString()}),
    );
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
              backgroundColor: state.errorMessage == 'mushaf.error.noReciter'
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
        buildWhen: (p, c) =>
            p.isDarkMode != c.isDarkMode ||
            p.isPlaying != c.isPlaying ||
            p.isPaused != c.isPaused,
        builder: (ctx, st) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: st.isDarkMode
                ? Colors.black
                : const Color(0xfff8f3e8),
            drawer: MushafDrawer(
              onBookmarkSaved: widget.onBookmarkSaved,
              scaffoldKey: _scaffoldKey,
              onGoToPage: () => _goToPage(context),
              onShowSavedPage: (page) => _showSavedPage(context, page),
              onSharePage: (page) => _sharePage(context, page),
            ),
            bottomNavigationBar: AudioPlayerBar(),
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
                            context.read<MushafBloc>().add(
                              MushafPageChanged(page),
                            );
                          },
                          itemBuilder: (context, index) {
                            final page = index + 1;
                            final pageData = state.pagesCache[page];
                            if (pageData == null) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return RepaintBoundary(
                              key: page == state.currentPage
                                  ? _pageCaptureKey
                                  : null,
                              child: MushafPageView(
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

                  if (!st.isPlaying)
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
                                color:
                                    (state.isDarkMode
                                            ? Colors.white
                                            : Colors.black)
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${state.currentPage} / 604',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: state.isDarkMode
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  if (!st.isPlaying)
                    Positioned(
                      top: 8,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (st.isDarkMode ? Colors.white : Colors.black)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.menu_rounded,
                            color: (st.isDarkMode ? Colors.white : Colors.black)
                                .withValues(alpha: 0.6),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
