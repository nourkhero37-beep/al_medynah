import 'package:flutter/material.dart';
import 'package:al_medynah/model/surah_model.dart';
import 'tafseer_ayah_screen.dart';
import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:al_medynah/main.dart';

class TafseerSurahListScreen extends StatefulWidget {
  const TafseerSurahListScreen({super.key});

  @override
  State<TafseerSurahListScreen> createState() => _TafseerSurahListScreenState();
}

class _TafseerSurahListScreenState extends State<TafseerSurahListScreen> {
  static const Color goldColor = Color(0xFFB8964E);
  static const Color darkBrown = Color(0xFF3E2A0F);

  final TextEditingController _searchController = TextEditingController();
  List<SurahModel> _filteredList = surahList;

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = surahList;
      } else {
        _filteredList = surahList.where((s) {
          return s.nameArabic.contains(query) ||
              s.nameEnglish.toLowerCase().contains(query.toLowerCase()) ||
              s.id.toString() == query;
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                AppLocalizations.of(context).tr('tafseer.appBar.title'),
                style: const TextStyle(
                  fontFamily: 'GE SS Two',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFF2493B4),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).tr('tafseer.search.hint'),
                      hintStyle: TextStyle(
                        fontFamily: 'GE SS Two',
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredList.length,
                    itemBuilder: (context, index) {
                      final surah = _filteredList[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TafseerAyahScreen(surah: surah),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/\u0627\u0631\u0642\u0627\u0645 \u0627\u0644\u0627\u064A\u0627\u062A.png',
                                          width: 42,
                                          height: 42,
                                          fit: BoxFit.contain,
                                        ),
                                        Text(
                                          '${surah.id}',
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          surah.nameArabic,
                                          style: TextStyle(
                                            fontFamily: 'GE SS Two',
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFF4DD0E1) : const Color(0xFF1E7FA0),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          surah.nameEnglish,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white54 : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: surah.revelationType == AppLocalizations.of(context).tr('ayahList.meccan')
                                              ? const Color(0xFF5C8A5C).withValues(alpha: 0.15)
                                              : const Color(0xFF2E86AB).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          surah.revelationType,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: surah.revelationType == AppLocalizations.of(context).tr('ayahList.meccan')
                                                ? const Color(0xFF5C8A5C)
                                                : const Color(0xFF2E86AB),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppLocalizations.of(context).tr('tafseer.appBar.subtitle', {'count': surah.versesCount.toString()}),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white38 : darkBrown.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_back_ios_rounded,
                                    size: 16,
                                    color: isDark ? const Color(0xFFD4B88A).withValues(alpha: 0.7) : goldColor.withValues(alpha: 0.7),
                                  ),
                                ],
                              ),
                            ),
                            if (index < _filteredList.length - 1)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Divider(
                                  height: 1,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
