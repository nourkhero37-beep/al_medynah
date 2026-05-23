import 'package:al_medynah/features/quran/tafseer/tafseer_surah_list_screen.dart';
import 'package:al_medynah/screens/ayah_list_page.dart';
import 'package:al_medynah/screens/quran_search_screen.dart';
import 'package:al_medynah/screens/reciter_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isDarkMode = true;

  final List<Map<String, String>> gridItems = [
    {'title': 'الصلوات', 'image': 'assets/images/logo.jpg'},
    {'title': 'الأذكار', 'image': 'assets/images/logo.jpg'},
    {'title': 'القراء', 'image': 'assets/images/logo.jpg'},
    {'title': 'التفسير', 'image': 'assets/images/logo.jpg'},
    {'title': 'التسبيح', 'image': 'assets/images/logo.jpg'},
    {'title': 'الأدعية', 'image': 'assets/images/logo.jpg'},
    {'title': 'المفضلة', 'image': 'assets/images/logo.jpg'},
    {'title': 'القبلة', 'image': 'assets/images/logo.jpg'},
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
          // الخلفية
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // طبقة شفافة
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
                  // الأزرار العلوية
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
                            setState(() {
                              isDarkMode = !isDarkMode;
                            });
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

                  // التاريخ
                  Text(
                    arabicDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // الكونتينر الكبير (زر)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AyahList(),
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

                  const SizedBox(height: 25),

                  // ✅  - حقل البحث عن آية
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QuranSearchScreen(),
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

                  const SizedBox(height: 25),

                  // الشبكة
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
                            if (gridItems[index]['title'] == 'القراء') {
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

// صفحة القرآن
