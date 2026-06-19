import 'package:flutter/material.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';
import 'azkar_chapters_screen.dart';
import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:al_medynah/main.dart';

class AzkarCategoriesScreen extends StatefulWidget {
  const AzkarCategoriesScreen({super.key});

  @override
  State<AzkarCategoriesScreen> createState() => _AzkarCategoriesScreenState();
}

class _AzkarCategoriesScreenState extends State<AzkarCategoriesScreen> {
  static const Color tealColor = Color(0xFF2493B4);

  final MuslimRepository _repo = MuslimRepository();
  List<AzkarCategory> _categories = [];
  bool _isLoading = true;

  final List<IconData> _icons = [
    Icons.wb_sunny_rounded,
    Icons.nights_stay_rounded,
    Icons.bedtime_rounded,
    Icons.alarm_rounded,
    Icons.mosque_rounded,
    Icons.water_drop_rounded,
    Icons.restaurant_rounded,
    Icons.home_rounded,
    Icons.directions_walk_rounded,
    Icons.favorite_rounded,
    Icons.airplanemode_active_rounded,
    Icons.card_travel_rounded,
    Icons.sick_rounded,
    Icons.cloud_rounded,
    Icons.visibility_rounded,
    Icons.thunderstorm_rounded,
    Icons.water_drop_rounded,
    Icons.waves_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _repo.getAzkarCategories(language: Language.ar);
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getIcon(int index) => _icons[index % _icons.length];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appDarkModeNotifier,
      builder: (context, isDark, _) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            appBar: AppBar(
              backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFF2493B4),
              elevation: 0,
              centerTitle: true,
              title: Text(
                AppLocalizations.of(context).tr('azkar.appBar.title'),
                style: const TextStyle(
                  fontFamily: 'GE SS Two',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: isDark ? const Color(0xFFD4B88A) : tealColor),
                  )
                : _categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 48,
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'تعذر تحميل الأذكار',
                              style: TextStyle(color: isDark ? Colors.white70 : null),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tealColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                setState(() => _isLoading = true);
                                _loadCategories();
                              },
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _categories.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AzkarChaptersScreen(category: category),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF333333) : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.07),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: tealColor.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: tealColor.withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      _getIcon(index),
                                      color: tealColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      category.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'GE SS Two',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? const Color(0xFF4DD0E1) : const Color(0xFF1E7FA0),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        );
      },
    );
  }
}

