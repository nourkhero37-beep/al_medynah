import 'package:al_medynah/model/hadith_model.dart';
import 'package:al_medynah/services/hadith_api_service.dart';
import 'package:flutter/material.dart';
import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:al_medynah/main.dart';

import 'package:al_medynah/screens/hadith_browser_screen.dart';

class HadithLibraryScreen extends StatefulWidget {
  const HadithLibraryScreen({super.key});

  @override
  State<HadithLibraryScreen> createState() => _HadithLibraryScreenState();
}

class _HadithLibraryScreenState extends State<HadithLibraryScreen> {
  final HadithApiService _api = HadithApiService();
  List<HadithCollection> _collections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final collections = await _api.getCollections();
      if (mounted) {
        setState(() {
          _collections = collections;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
                AppLocalizations.of(context).tr('hadith.appBar.title'),
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
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2493B4)),
                  )
                : _collections.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context).tr('hadith.error.loadLibrary'),
                          style: TextStyle(color: isDark ? Colors.white70 : null),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12),
                        child: GridView.builder(
                          itemCount: _collections.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          itemBuilder: (context, index) {
                            final book = _collections[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        HadithBrowserScreen(collection: book),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF333333) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        book.arabicName,
                                        style: TextStyle(
                                          fontFamily: 'GE SS Two',
                                          color: isDark ? const Color(0xFF4DD0E1) : const Color(0xFF1E7FA0),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        book.name,
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppLocalizations.of(context).tr('hadith.hadithCount', {'count': book.totalHadiths.toString()}),
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFFD4B88A) : const Color(0xFF2493B4),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        );
      },
    );
  }
}

