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
import 'package:al_medynah/services/bookmark_service.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isDarkMode = true;
  Map<String, dynamic>? _bookmark;

  @override
  void initState() {
    super.initState();
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    final bookmark = await BookmarkService().getBookmark();
    if (mounted) setState(() => _bookmark = bookmark);
  }

  final List<Map<String, String>> gridItems = [
    {'title': 'التلفزيون', 'image': 'assets/images/tv.png'},
    {'title': 'الأذكار', 'image': 'assets/images/azkar.png'},
    {'title': 'القراء', 'image': 'assets/images/reciters.png'},
    {'title': 'التفسير', 'image': 'assets/images/tafseer.png'},
    {'title': 'مكتبة الحديث', 'image': 'assets/images/hadyth.png'},
    {'title': 'أسماء الله الحسنى', 'image': 'assets/images/Allah_names.png'},
    {'title': 'أوقات الصلاة', 'image': 'assets/images/prayertime.png'},
    {'title': 'القبلة', 'image': 'assets/images/qublah.png'},
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    const days = [
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];

    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    final arabicDate =
        '${days[now.weekday % 7]}، ${now.day} ${months[now.month - 1]} ${now.year}';

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: isDarkMode
                ? Colors.black.withOpacity(0.75)
                : Colors.black.withOpacity(0.30),
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
                          color: Colors.white.withOpacity(0.15),
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
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.language, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  Text(
                    arabicDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
                      height: 220,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'القرآن الكريم',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'اقرأ واستمع للقرآن الكريم\nبواجهة جميلة ومريحة',
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

                  if (_bookmark != null)
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MushafScreen(
                              initialPage: _bookmark!['page'] as int,
                              highlightedVerseKey:
                                  _bookmark!['verse_key'] as String,
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
                          color: const Color(0xFF8B6914).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
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
                                  const Text(
                                    'أكمل القراءة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'سورة ${_bookmark!['surah_name']} — آية ${_bookmark!['ayah_number']}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                await BookmarkService().clearBookmark();
                                setState(() => _bookmark = null);
                              },
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withOpacity(0.7),
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
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.white70),
                          const SizedBox(width: 10),
                          Text(
                            'ابحث عن آية...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
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
                            if (gridItems[index]['title'] == 'التلفزيون') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TvScreen(),
                                ),
                              );
                            } else if (gridItems[index]['title'] == 'القراء') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReciterPage(),
                                ),
                              );
                            } else if (gridItems[index]['title'] == 'التفسير') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const TafseerSurahListScreen(),
                                ),
                              );
                            } else if (gridItems[index]['title'] == 'الأذكار') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AzkarCategoriesScreen(),
                                ),
                              );
                            } else if (gridItems[index]['title'] == 'القبلة') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const QiblaScreen(),
                                ),
                              );
                            } else if (gridItems[index]['title'] ==
                                'أوقات الصلاة') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrayerTimesScreen(),
                                ),
                              );
                            } else if (gridItems[index]['title'] ==
                                'مكتبة الحديث') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HadithLibraryScreen(),
                                ),
                              );
                            } else if (gridItems[index]['title'] ==
                                'أسماء الله الحسنى') {
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
                              color: Colors.white.withOpacity(0.12),
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
                                  gridItems[index]['title']!,
                                  textAlign: TextAlign.center,
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
