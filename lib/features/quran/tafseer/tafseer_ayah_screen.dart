import 'package:al_medynah/features/quran/tafseer/tafseer_service.dart';
import 'package:flutter/material.dart';
import 'package:al_medynah/model/surah_model.dart';
import 'package:al_medynah/l10n/app_localizations.dart';

class TafseerAyahScreen extends StatefulWidget {
  final SurahModel surah;

  const TafseerAyahScreen({super.key, required this.surah});

  @override
  State<TafseerAyahScreen> createState() => _TafseerAyahScreenState();
}

class _TafseerAyahScreenState extends State<TafseerAyahScreen> {
  static const Color darkBrown = Color(0xFF3E2A0F);

  final Map<int, String> _tafseerCache = {};
  int? _expandedAyah;
  bool _isLoadingTafseer = false;

  Future<void> _loadTafseer(int ayahNumber) async {
    if (_tafseerCache.containsKey(ayahNumber)) {
      setState(() => _expandedAyah = ayahNumber);
      return;
    }

    setState(() {
      _isLoadingTafseer = true;
      _expandedAyah = ayahNumber;
    });

    final verseKey = '${widget.surah.id}:$ayahNumber';
    final text = await TafseerService().fetchTafseer(verseKey);

    if (!mounted) return;

    setState(() {
      _tafseerCache[ayahNumber] =
          text ?? AppLocalizations.of(context).tr('tafseer.error.loadCache');
      _isLoadingTafseer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2493B4),
          elevation: 0,
          centerTitle: true,
          title: Column(
            children: [
              Text(
                'تفسير سورة ${widget.surah.nameArabic}',
                style: const TextStyle(
                  fontFamily: 'GE SS Two',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'تفسير الميسر • ${widget.surah.versesCount} آية',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: widget.surah.versesCount,
          itemBuilder: (context, index) {
            final ayahNumber = index + 1;
            final isExpanded = _expandedAyah == ayahNumber;
            final hasTafseer = _tafseerCache.containsKey(ayahNumber);

            return GestureDetector(
              onTap: () {
                if (isExpanded) {
                  setState(() => _expandedAyah = null);
                } else {
                  _loadTafseer(ayahNumber);
                }
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
                        AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: isExpanded
                                ? const Color(0xFF2493B4)
                                : Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'الآية $ayahNumber',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isExpanded
                                ? const Color(0xFF2493B4)
                                : darkBrown,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/images/ارقام الايات.png',
                                width: 36,
                                height: 36,
                                fit: BoxFit.contain,
                              ),
                              Text(
                                '$ayahNumber',
                                style: const TextStyle(
                                  color: darkBrown,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        color: const Color(0xFF2493B4).withValues(alpha: 0.3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: _isLoadingTafseer && !hasTafseer
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF2493B4),
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.menu_book_rounded,
                                      color: Color(0xFF2493B4),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppLocalizations.of(context)
                                          .tr('tafseer.header.title'),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2493B4),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _tafseerCache[ayahNumber] ?? '',
                                  textAlign: TextAlign.justify,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: darkBrown,
                                    height: 1.9,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],

                  if (index < widget.surah.versesCount - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


