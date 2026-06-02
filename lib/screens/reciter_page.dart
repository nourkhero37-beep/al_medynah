import 'package:al_medynah/model/reciters_model.dart';
import 'package:al_medynah/services/audio_manager_api.dart';
import 'package:flutter/material.dart';
import 'package:al_medynah/l10n/app_localizations.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF5ECD7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B6914),
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context).tr('reciter.appBar.title'),
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
                  Text(AppLocalizations.of(context).tr('reciter.error.load')),
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
                        color: Colors.black.withValues(alpha: 0.06),
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
                                ? goldColor.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.1),
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
                                color: goldColor.withValues(alpha: 0.15),
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
                                child: Text(
                                  AppLocalizations.of(context).tr('reciter.badge.selected'),
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
                                tooltip: AppLocalizations.of(context).tr('reciter.action.download'),
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
                                  'completed': '${_audioManager.downloadingSurah[rid] ?? 0}',
                                  'percent': '${((_audioManager.downloadProgress[rid] ?? 0) * 100).toInt()}',
                                }),
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