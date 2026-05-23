import 'package:al_medynah/features/quran/tafseer/tafseer_service.dart';
import 'package:flutter/material.dart';
import 'package:al_medynah/model/surah_model.dart';

class TafseerAyahScreen extends StatefulWidget {
  final SurahModel surah;

  const TafseerAyahScreen({super.key, required this.surah});

  @override
  State<TafseerAyahScreen> createState() => _TafseerAyahScreenState();
}

class _TafseerAyahScreenState extends State<TafseerAyahScreen> {
  static const Color goldColor = Color(0xFFB8964E);
  static const Color darkBrown = Color(0xFF3E2A0F);

  // ✅ كاش التفسير — ما نجيبه مرتين
  final Map<int, String> _tafseerCache = {};
  // ✅ تتبع أي آية مفتوحة
  int? _expandedAyah;
  bool _isLoadingTafseer = false;

  Future<void> _loadTafseer(int ayahNumber) async {
    // لو موجود بالكاش ما نطلبه مرة ثانية
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
          text ?? 'تعذر تحميل التفسير، تحقق من الاتصال.';
      _isLoadingTafseer = false;
    });
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
          title: Column(
            children: [
              Text(
                'تفسير سورة ${widget.surah.nameArabic}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: widget.surah.versesCount,
          itemBuilder: (context, index) {
            final ayahNumber = index + 1;
            final isExpanded = _expandedAyah == ayahNumber;
            final hasTafseer = _tafseerCache.containsKey(ayahNumber);

            return GestureDetector(
              onTap: () {
                if (isExpanded) {
                  // ✅ لو مفتوحة، نقفلها
                  setState(() => _expandedAyah = null);
                } else {
                  _loadTafseer(ayahNumber);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isExpanded
                      ? Border.all(color: goldColor.withOpacity(0.5), width: 1)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ✅ رأس الآية دائماً ظاهر
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // ✅ سهم الفتح/الإغلاق
                          AnimatedRotation(
                            turns: isExpanded ? 0.25 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: isExpanded ? goldColor : Colors.grey,
                            ),
                          ),

                          const Spacer(),

                          // ✅ نص "الآية X"
                          Text(
                            'الآية $ayahNumber',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isExpanded ? goldColor : darkBrown,
                            ),
                          ),

                          const SizedBox(width: 10),

                          // ✅ رقم الآية داخل الصورة
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

                    // ✅ التفسير — يظهر فقط لما الآية مفتوحة
                    if (isExpanded) ...[
                      Divider(
                        height: 1,
                        color: goldColor.withOpacity(0.3),
                        indent: 16,
                        endIndent: 16,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: _isLoadingTafseer && !hasTafseer
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF8B6914),
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ✅ label التفسير
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.menu_book_rounded,
                                        color: Color(0xFF8B6914),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'تفسير الميسر',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF8B6914),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // ✅ نص التفسير
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
