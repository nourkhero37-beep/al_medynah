import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:al_medynah/services/bookmark_service.dart';
import 'package:al_medynah/features/quran/bloc/mushaf_bloc.dart';
import 'package:al_medynah/features/quran/bloc/mushaf_event.dart';
import 'package:al_medynah/features/quran/bloc/mushaf_state.dart';
import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:al_medynah/main.dart';

class MushafDrawer extends StatelessWidget {
  final VoidCallback? onBookmarkSaved;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onGoToPage;
  final void Function(int?) onShowSavedPage;
  final void Function(int) onSharePage;

  const MushafDrawer({
    super.key,
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
            color: const Color(0xFF1E7FA0),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _drawerItem(
                          icon: Icons.bookmark_add_rounded,
                          text: tr('mushaf.menu.savePage'),
                          onTap: () async {
                            await BookmarkService().savePageBookmark(
                              state.currentPage,
                            );
                            onBookmarkSaved?.call();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  tr('mushaf.bookmark.pageSaved', {
                                    'page': state.currentPage.toString(),
                                  }),
                                ),
                                backgroundColor: const Color(0xFF2493B4),
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
                            final savedPage = await BookmarkService()
                                .getPageBookmark();
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
                            final newScale = (state.fontScale + 0.1).clamp(
                              0.5,
                              2.0,
                            );
                            context.read<MushafBloc>().add(
                              MushafFontSizeChanged(newScale),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  tr('mushaf.menu.fontSizeChanged', {
                                    'size': (newScale * 100).toInt().toString(),
                                  }),
                                ),
                                backgroundColor: const Color(0xFF2493B4),
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
                            final newScale = (state.fontScale - 0.1).clamp(
                              0.5,
                              2.0,
                            );
                            context.read<MushafBloc>().add(
                              MushafFontSizeChanged(newScale),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  tr('mushaf.menu.fontSizeChanged', {
                                    'size': (newScale * 100).toInt().toString(),
                                  }),
                                ),
                                backgroundColor: const Color(0xFF2493B4),
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
                              ? const Icon(
                                  Icons.check,
                                  color: Color(0xFF2493B4),
                                  size: 20,
                                )
                              : null,
                          onTap: () {
                            scaffoldKey.currentState?.closeDrawer();
                            final newMode = !state.isDarkMode;
                            context.read<MushafBloc>().add(
                              MushafDarkModeToggled(newMode),
                            );
                            appDarkModeNotifier.value = newMode;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  tr(
                                    newMode
                                        ? 'mushaf.menu.darkModeOn'
                                        : 'mushaf.menu.darkModeOff',
                                  ),
                                ),
                                backgroundColor: const Color(0xFF2493B4),
                                duration: const Duration(seconds: 1),
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
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'GE SS Two'),
      ),
      trailing: trailing,
      onTap: onTap,
      dense: true,
    );
  }
}