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
  bool isDarkMode = false;
  int? _bookmarkPage;

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

  String _currentLanguageName(AppLocalizations loc) {
    switch (appLocaleNotifier.value.languageCode) {
      case 'ar':
        return loc.tr('lang.arabic');
      case 'en':
        return loc.tr('lang.english');
      case 'tr':
        return loc.tr('lang.turkish');
      default:
        return loc.tr('lang.arabic');
    }
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final localeCode = AppLocalizations.of(context).localeCode;
    final loc = AppLocalizations.of(context);
    final gregorianStr = DateFormat.yMMMMEEEEd(localeCode).format(now);
    final hijriStr = _formatHijriDate(localeCode);

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
                : Colors.black.withValues(alpha: 0.12),
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
                          color: isDarkMode
                              ? const Color(0xFF2A2A2A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() => isDarkMode = !isDarkMode);
                          },
                          icon: Icon(
                            isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: isDarkMode
                                ? Colors.white70
                                : const Color(0xFF3E2A0F),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF2A2A2A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: PopupMenuButton<String>(
                          onSelected: (code) async {
                            final newLocale = Locale(code);
                            appLocaleNotifier.value = newLocale;
                            await LocaleService.setLocale(newLocale);
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'ar',
                              child: Text(loc.tr('lang.arabic')),
                            ),
                            PopupMenuItem(
                              value: 'en',
                              child: Text(loc.tr('lang.english')),
                            ),
                            PopupMenuItem(
                              value: 'tr',
                              child: Text(loc.tr('lang.turkish')),
                            ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentLanguageName(loc),
                                  style: TextStyle(
                                    fontFamily: 'GE SS Two',
                                    color: isDarkMode
                                        ? Colors.white70
                                        : const Color(0xFF3E2A0F),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : const Color(0xFF3E2A0F),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  Column(
                    children: [
                      Text(
                        hijriStr,
                        style: const TextStyle(
                          fontFamily: 'GE SS Two',
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gregorianStr,
                        style: const TextStyle(
                          fontFamily: 'GE SS Two',
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                        color: isDarkMode
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.tr('home.hero.title'),
                                  style: TextStyle(
                                    fontFamily: 'GE SS Two',
                                    color: isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF3E2A0F),
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  loc.tr('home.hero.subtitle'),
                                  style: TextStyle(
                                    fontFamily: 'GE SS Two',
                                    color: isDarkMode
                                        ? Colors.white70
                                        : const Color(
                                            0xFF3E2A0F,
                                          ).withValues(alpha: 0.7),
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
                          color: isDarkMode
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFF8B6914).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode
                                ? const Color(0xFF8B6914).withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.2),
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
                                    loc.tr('home.bookmark.resume'),
                                    style: const TextStyle(
                                      fontFamily: 'GE SS Two',
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'الصفحة $_bookmarkPage',
                                    style: const TextStyle(
                                      fontFamily: 'GE SS Two',
                                      color: Colors.white,
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
                        color: isDarkMode
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: isDarkMode
                                ? Colors.white70
                                : const Color(
                                    0xFF3E2A0F,
                                  ).withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            loc.tr('home.search.hint'),
                            style: TextStyle(
                              fontFamily: 'GE SS Two',
                              color: isDarkMode
                                  ? Colors.white70
                                  : const Color(
                                      0xFF3E2A0F,
                                    ).withValues(alpha: 0.7),
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
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.0,
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
                              color: isDarkMode
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                                  loc.tr(
                                    'home.grid.${gridItems[index]['key']}',
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'GE SS Two',
                                    color: isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF3E2A0F),
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
