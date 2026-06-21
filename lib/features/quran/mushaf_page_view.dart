import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:al_medynah/model/quran_page_model.dart';
import 'package:al_medynah/features/quran/bloc/mushaf_bloc.dart';
import 'package:al_medynah/features/quran/bloc/mushaf_event.dart';
import 'package:al_medynah/features/quran/tafseer/tafseer_bottom_sheet.dart';
import 'package:al_medynah/l10n/app_localizations.dart';

class MushafPageView extends StatelessWidget {
  final int page;
  final QuranPage pageData;
  final String? selectedVerseKey;
  final double fontScale;
  final bool isDarkMode;
  final int textColor;

  const MushafPageView({
    super.key,
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
    0xFF800000,
    0xFFFF8F00,
    0xFF5D4037,
    0xFF6A1B9A,
    0xFF1B5E20,
    0xFF1A237E,
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
                  context.read<MushafBloc>().add(MushafTextColorChanged(c));
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isWhite
                          ? Colors.grey.shade400
                          : Colors.transparent,
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
    final lines = pageData.lines;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSpecialPage = page == 1 || page == 2;
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);

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
                  if (line.words.isEmpty) return const SizedBox();

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isSpecialPage ? 1 : 0,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          textDirection: TextDirection.rtl,
                          children: line.words.map<Widget>((word) {
                            final String char = word.char;
                            final String font = word.font;
                            final String type = word.type;
                            final String? verseKey = word.verseKey;

                            if (char.isEmpty) return const SizedBox();

                            if (type == 'surah_header') {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/surah_header_frames.png',
                                    width: screenWidth * 1.20 * fontScale * textScale,
                                    height: screenHeight * 0.06 * fontScale * textScale,
                                    fit: BoxFit.contain,
                                  ),
                                  Transform.translate(
                                    offset: Offset(0, -screenHeight * 0.006 * fontScale * textScale),
                                    child: Text(
                                      char,
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: font,
                                        fontSize:
                                            screenHeight * 0.033 * fontScale,
                                        color: Color(textColor),
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            final bool isHighlighted =
                                verseKey != null &&
                                verseKey == selectedVerseKey;

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
                                if (verseKey == null || longPressPos == null) {
                                  return;
                                }
                                final pos = longPressPos!;
                                final tr = AppLocalizations.of(context).tr;
                                showMenu<String>(
                                  context: context,
                                  position: RelativeRect.fromLTRB(
                                    pos.dx,
                                    pos.dy,
                                    pos.dx,
                                    pos.dy,
                                  ),
                                  items: [
                                    PopupMenuItem(
                                      value: 'tafseer',
                                      child: Text(
                                        tr('mushaf.longpress.tafseer'),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'play',
                                      child: Text(tr('mushaf.longpress.play')),
                                    ),
                                    PopupMenuItem(
                                      value: 'color',
                                      child: Text(
                                        tr('mushaf.longpress.changeColor'),
                                      ),
                                    ),
                                  ],
                                ).then((value) {
                                  if (value == null) return;
                                  if (!context.mounted) return;
                                  switch (value) {
                                    case 'tafseer':
                                      TafseerBottomSheet.show(
                                        context,
                                        verseKey,
                                      );
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
                                      ? const Color(
                                          0xFFB8D4A8,
                                        ).withValues(alpha: 0.6)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  char,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontFamily: font,
                                    fontSize:
                                        (isSpecialPage
                                            ? screenHeight * 0.024
                                            : screenHeight * 0.022) *
                                        fontScale,
                                    color: isHighlighted
                                        ? const Color(0xFF2E7D32)
                                        : Color(textColor),
                                    height:
                                        (isSpecialPage ? 3 : 1.9) /
                                        fontScale.clamp(0.7, 1.3),
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