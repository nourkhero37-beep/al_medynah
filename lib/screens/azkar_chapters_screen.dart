import 'package:flutter/material.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

class AzkarChaptersScreen extends StatefulWidget {
  final AzkarCategory category;

  const AzkarChaptersScreen({super.key, required this.category});

  @override
  State<AzkarChaptersScreen> createState() => _AzkarChaptersScreenState();
}

class _AzkarChaptersScreenState extends State<AzkarChaptersScreen> {
  static const Color goldColor = Color(0xFFB8964E);
  static const Color darkBrown = Color(0xFF3E2A0F);

  final MuslimRepository _repo = MuslimRepository();
  List<AzkarChapter> _chapters = [];
  bool _isLoading = true;

  final Map<int, List<AzkarItem>> _azkarCache = {};
  int? _expandedChapterId;
  bool _isLoadingItems = false;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    try {
      final chapters = await _repo.getAzkarChapters(
        language: Language.ar,
        categoryId: widget.category.id,
      );
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAzkarItems(int chapterId) async {
    if (_azkarCache.containsKey(chapterId)) {
      setState(() => _expandedChapterId = chapterId);
      return;
    }

    setState(() {
      _isLoadingItems = true;
      _expandedChapterId = chapterId;
    });

    try {
      final items = await _repo.getAzkarItems(
        language: Language.ar,
        chapterId: chapterId,
      );
      if (mounted) {
        setState(() {
          _azkarCache[chapterId] = items;
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingItems = false);
    }
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
                widget.category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_chapters.length} باب',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B6914)),
              )
            : _chapters.isEmpty
            ? const Center(child: Text('لا توجد أبواب'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                itemCount: _chapters.length,
                itemBuilder: (context, index) {
                  final chapter = _chapters[index];
                  final isExpanded = _expandedChapterId == chapter.id;
                  final hasItems = _azkarCache.containsKey(chapter.id);

                  return GestureDetector(
                    onTap: () {
                      if (isExpanded) {
                        setState(() => _expandedChapterId = null);
                      } else {
                        _loadAzkarItems(chapter.id);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isExpanded
                            ? Border.all(
                                color: goldColor.withValues(alpha: 0.5),
                                width: 1,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // رأس الباب
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                AnimatedRotation(
                                  turns: isExpanded ? 0.25 : 0,
                                  duration: const Duration(milliseconds: 250),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: isExpanded ? goldColor : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    chapter.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isExpanded ? goldColor : darkBrown,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: goldColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.menu_book_rounded,
                                      color: Color(0xFF8B6914),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // الأذكار — تظهر لما الباب مفتوح
                          if (isExpanded) ...[
                            Divider(
                              height: 1,
                              color: goldColor.withValues(alpha: 0.3),
                              indent: 16,
                              endIndent: 16,
                            ),
                            if (_isLoadingItems && !hasItems)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF8B6914),
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            else if (hasItems)
                              ..._azkarCache[chapter.id]!.asMap().entries.map((
                                entry,
                              ) {
                                final i = entry.key;
                                final azkarItem = entry.value;
                                return _AzkarItemCard(
                                  item: azkarItem,
                                  index: i + 1,
                                  isLast:
                                      i == _azkarCache[chapter.id]!.length - 1,
                                );
                              }),
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

class _AzkarItemCard extends StatefulWidget {
  final AzkarItem item;
  final int index;
  final bool isLast;

  const _AzkarItemCard({
    required this.item,
    required this.index,
    required this.isLast,
  });

  @override
  State<_AzkarItemCard> createState() => _AzkarItemCardState();
}

class _AzkarItemCardState extends State<_AzkarItemCard> {
  static const Color goldColor = Color(0xFFB8964E);
  static const Color darkBrown = Color(0xFF3E2A0F);

  // عداد ثابت بـ 1 لأن الباكج ما يوفر repeatCount
  int _count = 0;
  static const int _total = 1;

  void _increment() {
    if (_count < _total) setState(() => _count++);
  }

  void _reset() {
    setState(() => _count = 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _count >= _total;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
      decoration: BoxDecoration(
        border: widget.isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: goldColor.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // رقم الذكر
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: goldColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.index}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B6914),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // نص الذكر
          Text(
            widget.item.item,
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 16,
              color: isDone ? Colors.grey : darkBrown,
              height: 2.0,
            ),
          ),

          // المصدر (لو موجود)
          if (widget.item.reference.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: goldColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: goldColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF8B6914),
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.item.reference,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 11,
                        color: darkBrown.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // زر التأشير كمقروء
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: isDone ? _reset : _increment,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF8B6914)
                        : goldColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: goldColor.withValues(alpha: isDone ? 0 : 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDone ? Icons.refresh_rounded : Icons.check_rounded,
                        size: 14,
                        color: isDone ? Colors.white : const Color(0xFF8B6914),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isDone ? 'إعادة' : 'تم',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDone
                              ? Colors.white
                              : const Color(0xFF8B6914),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
