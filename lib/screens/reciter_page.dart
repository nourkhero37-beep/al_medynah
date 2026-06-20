import 'package:al_medynah/model/reciters_model.dart';
import 'package:al_medynah/services/audio_manager_api.dart';
import 'package:flutter/material.dart';
import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:al_medynah/main.dart';

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

  @override
  void initState() {
    super.initState();
    _audioManager.downloadNotifier.addListener(_onDownloadStateChanged);
    _init();
  }

  @override
  void dispose() {
    _audioManager.downloadNotifier.removeListener(_onDownloadStateChanged);
    super.dispose();
  }

  void _onDownloadStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _init() async {
    await _audioManager.loadSelectedReciter();
    setState(() => _selectedReciterId = _audioManager.currentReciterId);

    final reciters = await _audioManager.fetchReciters();

    for (final r in reciters) {
      final rid = r.id.toString();
      if (_audioManager.downloadProgress[rid] == null && !(_audioManager.isDownloaded[rid] ?? false)) {
        final first = await _audioManager.isSurahDownloaded(rid, 1);
        final last = await _audioManager.isSurahDownloaded(rid, 114);
        _audioManager.isDownloaded[rid] = first && last;
      }
    }

    if (mounted) {
      setState(() {
        _reciters = reciters;
        _isLoadingReciters = false;
      });
    }
  }

  Future<void> _download(RecitersModel reciter) async {
    try {
      await _audioManager.startDownload(reciter);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).tr('reciter.download.success', {'name': reciter.nameArabic})),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).tr('reciter.download.fail')),
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
          content: Text(AppLocalizations.of(context).tr('reciter.selected', {'name': reciter.nameArabic})),
          backgroundColor: const Color(0xFF8B6914),
        ),
      );
    }
  }

  Future<void> _delete(RecitersModel reciter) async {
    final rid = reciter.id.toString();
    await _audioManager.deleteReciter(rid);
    if (mounted) {
      setState(() {
        if (_selectedReciterId == rid) _selectedReciterId = null;
      });
    }
  }

  void _showDeleteDialog(RecitersModel reciter) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).tr('reciter.delete.title')),
        content: Text(AppLocalizations.of(context).tr('reciter.delete.confirm', {'name': reciter.nameArabic})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).tr('reciter.cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _delete(reciter);
            },
            child: Text(AppLocalizations.of(context).tr('reciter.delete'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
                AppLocalizations.of(context).tr('reciter.appBar.title'),
                style: const TextStyle(
                  fontFamily: 'GE SS Two',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: _isLoadingReciters
                ? Center(child: CircularProgressIndicator(color: goldColor))
                : _reciters.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off, size: 48, color: isDark ? Colors.white38 : Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(context).tr('reciter.error.load'),
                              style: TextStyle(color: isDark ? Colors.white70 : null),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _init,
                              child: Text(AppLocalizations.of(context).tr('reciter.retry')),
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
                          final isDownloaded = _audioManager.isDownloaded[rid] ?? false;
                          final isSelected = _selectedReciterId == rid;
                          final progress = _audioManager.downloadProgress[rid];
                          final isDownloading = progress != null;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF2493B4).withValues(alpha: 0.15)
                                            : isDark
                                                ? Colors.white.withValues(alpha: 0.1)
                                                : Colors.grey.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.record_voice_over_rounded,
                                        color: isSelected
                                            ? const Color(0xFF2493B4)
                                            : isDark ? Colors.white54 : Colors.grey,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reciter.nameArabic,
                                            textDirection: TextDirection.rtl,
                                            style: TextStyle(
                                              fontFamily: 'GE SS Two',
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? const Color(0xFF4DD0E1) : const Color(0xFF1E7FA0),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: goldColor.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  reciter.rewaya,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? const Color(0xFFD4B88A) : darkBrown,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              if (isSelected) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF2493B4).withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    AppLocalizations.of(context).tr('reciter.badge.selected'),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF2493B4),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isDownloaded && !isDownloading)
                                          IconButton(
                                            onPressed: () => _download(reciter),
                                            icon: const Icon(
                                              Icons.download_rounded,
                                              color: Color(0xFF2E86AB),
                                            ),
                                            tooltip: AppLocalizations.of(context).tr('reciter.action.download'),
                                          )
                                        else if (isDownloading)
                                          const SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: CircularProgressIndicator(
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
                                              tooltip: AppLocalizations.of(context).tr('reciter.action.select'),
                                            ),
                                          IconButton(
                                            onPressed: () => _showDeleteDialog(reciter),
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.red,
                                            ),
                                            tooltip: AppLocalizations.of(context).tr('reciter.delete'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              if (isDownloading)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: _audioManager.surahDownloadProgress[rid],
                                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                          color: goldColor,
                                          minHeight: 6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppLocalizations.of(context).tr('reciter.progress', {
                                          'completed': '${_audioManager.downloadingSurah[rid] ?? ''}',
                                          'percent': '${((_audioManager.surahDownloadProgress[rid] ?? 0) * 100).toInt()}',
                                        }),
                                        style: TextStyle(color: isDark ? Colors.white70 : null),
                                      ),
                                    ],
                                  ),
                                ),

                              if (index < _reciters.length - 1)
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
