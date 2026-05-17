import 'package:al_medynah/model/reciters_model.dart';
import 'package:al_medynah/services/audio_manager_api.dart';
import 'package:flutter/material.dart';

class ReciterPage extends StatefulWidget {
  const ReciterPage({super.key});

  @override
  State<ReciterPage> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends State<ReciterPage> {
  static const Color goldColor = Color(0xFFB8964E);
  static const Color darkBrown = Color(0xFF3E2A0F);

  final AudioManager _audioManager = AudioManager();

  List<RecitersModel> _reciters = [];
  bool _isLoadingReciters = true;
  String? _selectedReciterId;

  final Map<String, double?> _downloadProgress = {};
  final Map<String, bool> _isDownloaded = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _audioManager.loadSelectedReciter();
    setState(() => _selectedReciterId = _audioManager.currentReciterId);

    final reciters = await _audioManager.fetchReciters();

    for (final r in reciters) {
      final rid = r.id.toString();
      final first = await _audioManager.isSurahDownloaded(rid, 1);
      final last = await _audioManager.isSurahDownloaded(rid, 114);
      _isDownloaded[rid] = first && last;
    }

    if (mounted) {
      setState(() {
        _reciters = reciters;
        _isLoadingReciters = false;
      });
    }
  }

  Future<void> _download(RecitersModel reciter) async {
    final rid = reciter.id.toString();
    setState(() => _downloadProgress[rid] = 0.0);

    try {
      const total = 114;

      // نحسب كم سورة محملة مسبقاً
      int completed = 0;
      for (int s = 1; s <= total; s++) {
        final downloaded = await _audioManager.isSurahDownloaded(rid, s);
        if (downloaded) {
          completed++;
        } else {
          break;
        }
      }

      if (mounted) {
        setState(() => _downloadProgress[rid] = completed / total);
      }

      // نكمل من حيث توقفنا
      for (int surah = completed + 1; surah <= total; surah++) {
        // ✅ بدون onProgress
        await _audioManager.downloadSurah(rid, surah, reciter.serverUrl);
        completed++;
        if (mounted) {
          setState(() => _downloadProgress[rid] = completed / total);
        }
      }

      if (mounted) {
        setState(() {
          _downloadProgress[rid] = null;
          _isDownloaded[rid] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحميل ${reciter.nameArabic} كاملاً ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadProgress[rid] = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل التحميل، تحقق من الاتصال'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _select(RecitersModel reciter) async {
    final rid = reciter.id.toString();
    await _audioManager.saveSelectedReciter(
      rid,
      reciter.serverUrl,
      reciter.nameArabic,
    );
    setState(() => _selectedReciterId = rid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم اختيار ${reciter.nameArabic}'),
          backgroundColor: const Color(0xFF8B6914),
        ),
      );
    }
  }

  Future<void> _delete(RecitersModel reciter) async {
    final rid = reciter.id.toString();
    await _audioManager.deleteReciter(rid);
    setState(() {
      _isDownloaded[rid] = false;
      if (_selectedReciterId == rid) _selectedReciterId = null;
    });
  }

  void _showDeleteDialog(RecitersModel reciter) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف القارئ'),
        content: Text('هل تريد حذف تحميل ${reciter.nameArabic} كاملاً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _delete(reciter);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5ECD7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B6914),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'القراء',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingReciters
          ? const Center(child: CircularProgressIndicator())
          : _reciters.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('تعذر تحميل القراء'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _init,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _reciters.length,
              itemBuilder: (context, index) {
                final reciter = _reciters[index];
                final rid = reciter.id.toString();
                final isDownloaded = _isDownloaded[rid] ?? false;
                final isSelected = _selectedReciterId == rid;
                final progress = _downloadProgress[rid];
                final isDownloading = progress != null;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: goldColor, width: 2)
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
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? goldColor.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.record_voice_over_rounded,
                            color: isSelected ? goldColor : Colors.grey,
                            size: 26,
                          ),
                        ),
                        title: Text(
                          reciter.nameArabic,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: darkBrown,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: goldColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                reciter.rewaya,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: darkBrown,
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: goldColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'محدد',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isDownloaded && !isDownloading)
                              IconButton(
                                onPressed: () => _download(reciter),
                                icon: const Icon(
                                  Icons.download_rounded,
                                  color: Color(0xFF2E86AB),
                                ),
                                tooltip: 'تحميل القرآن كامل',
                              )
                            else if (isDownloading)
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 3,
                                  color: goldColor,
                                ),
                              )
                            else ...[
                              if (!isSelected)
                                IconButton(
                                  onPressed: () => _select(reciter),
                                  icon: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Colors.green,
                                  ),
                                  tooltip: 'اختيار',
                                ),
                              IconButton(
                                onPressed: () => _showDeleteDialog(reciter),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                ),
                                tooltip: 'حذف',
                              ),
                            ],
                          ],
                        ),
                      ),

                      // شريط التقدم
                      if (isDownloading)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey.withOpacity(0.2),
                                  color: goldColor,
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'سورة ${(progress! * 114).toInt()} / 114',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: darkBrown.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
