import 'package:flutter/material.dart';
import 'package:al_medynah/model/surah_model.dart';
import 'tafseer_ayah_screen.dart';
import 'package:al_medynah/l10n/app_localizations.dart';

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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5ECD7),
        appBar: AppBar(
          backgroundColor: const Color(0xFF8B6914),
          elevation: 0,
          centerTitle: true,
          title: Text(
            AppLocalizations.of(context).tr('tafseer.appBar.title'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                textDirection: TextDirection.rtl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).tr('tafseer.search.hint'),
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
          ),
        ),
        body: ListView.builder(
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
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ✅ رقم السورة
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/images/ارقام الايات.png',
                            width: 42,
                            height: 42,
                            fit: BoxFit.contain,
                          ),
                          Text(
                            '${surah.id}',
                            style: const TextStyle(
                              color: darkBrown,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // ✅ اسم السورة
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            surah.nameArabic,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: darkBrown,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            surah.nameEnglish,
                            style: TextStyle(
                              fontSize: 12,
                              color: darkBrown.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ نوع + عدد الآيات
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
                            color: darkBrown.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),

                    // ✅ سهم للتنقل
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 16,
                      color: goldColor.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
