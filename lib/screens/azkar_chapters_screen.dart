import 'package:flutter/material.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';
import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:al_medynah/main.dart';

class AzkarChaptersScreen extends StatefulWidget {
  final AzkarCategory category;

  const AzkarChaptersScreen({super.key, required this.category});

  @override
  State<AzkarChaptersScreen> createState() => _AzkarChaptersScreenState();
}

class _AzkarChaptersScreenState extends State<AzkarChaptersScreen> {

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
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleChapter(int chapterId) async {
    if (_expandedChapterId == chapterId) {
      setState(() => _expandedChapterId = null);
      return;
    }

    setState(() {
      _expandedChapterId = chapterId;
      _isLoadingItems = !_azkarCache.containsKey(chapterId);
    });

    if (!_azkarCache.containsKey(chapterId)) {
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
      } catch (_) {
        if (mounted) setState(() => _isLoadingItems = false);
      }
    }
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
                widget.category.name,
                style: const TextStyle(
                  fontFamily: 'GE SS Two',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: isDark ? const Color(0xFFD4B88A) : const Color(0xFF2493B4)),
                  )
                : ListView.builder(
                    itemCount: _chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = _chapters[index];
                      final isExpanded = _expandedChapterId == chapter.id;

                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleChapter(chapter.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      chapter.name,
                                      style: TextStyle(
                                        fontFamily: 'GE SS Two',
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? const Color(0xFF4DD0E1) : const Color(0xFF1E7FA0),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less_rounded
                                        : Icons.expand_more_rounded,
                                    color: isDark ? const Color(0xFFD4B88A) : const Color(0xFF2493B4),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (isExpanded) ...[
                            if (_isLoadingItems && !_azkarCache.containsKey(chapter.id))
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF2493B4),
                                  ),
                                ),
                              )
                            else if (_azkarCache.containsKey(chapter.id))
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

                          if (index < _chapters.length - 1)
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
                      );
                    },
                  ),
          ),
        );
      },
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
  static const Color darkBrown = Color(0xFF3E2A0F);

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
    final isDark = appDarkModeNotifier.value;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
      decoration: BoxDecoration(
        border: widget.isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFFD4B88A).withValues(alpha: 0.15)
                      : const Color(0xFF2493B4).withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF2493B4).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF4DD0E1) : const Color(0xFF2493B4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.item.item,
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 16,
              color: isDone ? Colors.grey : (isDark ? Colors.white70 : darkBrown),
              height: 2.0,
            ),
          ),
          if (widget.item.reference.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2493B4).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF2493B4).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: isDark ? const Color(0xFF4DD0E1) : const Color(0xFF2493B4),
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.item.reference,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : darkBrown.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
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
                        ? const Color(0xFF2493B4)
                        : const Color(0xFF2493B4).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFF2493B4).withValues(alpha: 0)
                          : const Color(0xFF2493B4).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDone ? Icons.refresh_rounded : Icons.check_rounded,
                        size: 14,
                        color: isDone
                            ? Colors.white
                            : const Color(0xFF2493B4),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isDone
                            ? AppLocalizations.of(context)
                                .tr('azkarChapters.reset')
                            : AppLocalizations.of(context)
                                .tr('azkarChapters.done'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDone
                              ? Colors.white
                              : const Color(0xFF2493B4),
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
