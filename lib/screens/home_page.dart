import 'package:al_medynah/features/quran/mushaf_screen.dart';
import 'package:al_medynah/features/quran/tafseer/tafseer_surah_list_screen.dart';
import 'package:al_medynah/screens/ayah_list_page.dart';
import 'package:al_medynah/screens/azkar_categories_screen.dart';
import 'package:al_medynah/screens/hadith_library_screen.dart';
import 'package:al_medynah/screens/names_of_allah_screen.dart';
import 'package:al_medynah/screens/prayer_time_screen.dart';
import 'package:al_medynah/screens/quran_search_screen.dart';
import 'package:al_medynah/screens/qibla_screen.dart';
import 'package:al_medynah/screens/reciter_page.dart';
import 'package:al_medynah/screens/tv_screen.dart';
import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:al_medynah/main.dart';
import 'package:al_medynah/services/bookmark_service.dart';
import 'package:al_medynah/services/locale_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:hijri/hijri_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isDarkMode = true;
  int? _bookmarkPage;
  bool _showGregorian = false;

  @override
  void initState() {
    super.initState();
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    final page = await BookmarkService().getPageBookmark();
    if (mounted) setState(() => _bookmarkPage = page);
  }

  String _formatHijriDate(String localeCode) {
    final locale = switch (localeCode) {
      'ar' => 'ar',
      'tr' => 'tr',
      _ => 'en',
    };
    HijriCalendar.setLocal(locale);
    return HijriCalendar.fromDate(DateTime.now()).fullDate();
  }

  final List<Map<String, String>> gridItems = [
    {'key': 'tv', 'image': 'assets/images/tv.png'},
    {'key': 'azkar', 'image': 'assets/images/azkar.png'},
    {'key': 'reciters', 'image': 'assets/images/reciters.png'},
    {'key': 'tafseer', 'image': 'assets/images/tafseer.png'},
    {'key': 'hadith', 'image': 'assets/images/hadyth.png'},
    {'key': 'namesOfAllah', 'image': 'assets/images/Allah_names.png'},
    {'key': 'prayerTimes', 'image': 'assets/images/prayertime.png'},
    {'key': 'qibla', 'image': 'assets/images/qublah.png'},
  ];

  Future<void> _showLanguageDialog() async {
    final loc = AppLocalizations.of(context);
    final current = appLocaleNotifier.value;
    await showDialog<String>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFFF5ECD7),
            title: Text(
              loc.tr('lang.title'),
              style: const TextStyle(color: Color(0xFF3E2A0F)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _langOption(ctx, loc, current, 'ar', 'lang.arabic'),
                _langOption(ctx, loc, current, 'en', 'lang.english'),
                _langOption(ctx, loc, current, 'tr', 'lang.turkish'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _langOption(
    BuildContext ctx,
    AppLocalizations loc,
    Locale current,
    String code,
    String labelKey,
  ) {
    final selected = current.languageCode == code;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: selected ? const Color(0xFF8B6914) : Colors.white,
            foregroundColor: selected ? Colors.white : const Color(0xFF3E2A0F),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected
                    ? const Color(0xFF8B6914)
                    : const Color(0xFFB8964E).withValues(alpha: 0.3),
              ),
            ),
          ),
          onPressed: () async {
            final newLocale = Locale(code);
            appLocaleNotifier.value = newLocale;
            await LocaleService.setLocale(newLocale);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: Text(
            loc.tr(labelKey),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final localeCode = AppLocalizations.of(context).localeCode;
    final gregorianStr = DateFormat.yMMMMEEEEd(localeCode).format(now);
    final hijriStr = _formatHijriDate(localeCode);
    final dateStr = _showGregorian ? gregorianStr : hijriStr;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background2.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.75)
                : Colors.black.withValues(alpha: 0.30),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() => isDarkMode = !isDarkMode);
                          },
                          icon: Icon(
                            isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed: _showLanguageDialog,
                          icon: const Icon(Icons.language, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  GestureDetector(
                    onLongPressStart: (_) => setState(() => _showGregorian = true),
                    onLongPressEnd: (_) => setState(() => _showGregorian = false),
                    child: Text(
                      dateStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AyahList(onBookmarkSaved: _loadBookmark),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).tr('home.hero.title'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).tr('home.hero.subtitle'),
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Image.asset('assets/images/logo.jpg', width: 120),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_bookmarkPage != null)
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MushafScreen(
                              initialPage: _bookmarkPage!,
                              
                                  
                              onBookmarkSaved: _loadBookmark,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF8B6914,
                          ).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bookmark_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    ).tr('home.bookmark.resume'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'الصفحة ',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                await BookmarkService().clearPageBookmark();
                                setState(() => _bookmarkPage = null);
                              },
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              QuranSearchScreen(onBookmarkSaved: _loadBookmark),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.white70),
                          const SizedBox(width: 10),
                          Text(
                            AppLocalizations.of(context).tr('home.search.hint'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: GridView.builder(
                      itemCount: gridItems.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            switch (gridItems[index]['key']) {
                              case 'tv':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TvScreen(),
                                  ),
                                );
                              case 'reciters':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ReciterPage(),
                                  ),
                                );
                              case 'tafseer':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const TafseerSurahListScreen(),
                                  ),
                                );
                              case 'azkar':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AzkarCategoriesScreen(),
                                  ),
                                );
                              case 'qibla':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const QiblaScreen(),
                                  ),
                                );
                              case 'prayerTimes':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PrayerTimesScreen(),
                                  ),
                                );
                              case 'hadith':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HadithLibraryScreen(),
                                  ),
                                );
                              case 'namesOfAllah':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NamesOfAllahScreen(),
                                  ),
                                );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    gridItems[index]['image']!,
                                    height: 45,
                                    width: 45,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).tr('home.grid.${gridItems[index]['key']}'),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}







