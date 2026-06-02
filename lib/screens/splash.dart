import 'dart:async';
import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:al_medynah/screens/home_page.dart';
import 'package:al_medynah/services/quran_data_service.dart';
import 'package:al_medynah/screens/language_selection_page.dart';
import 'package:al_medynah/services/locale_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:al_medynah/features/quran/mushaf_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color goldColor = Color(0xFFB8964E);

  final QuranDataService _dataService = QuranDataService();

  bool _isChecking = true;
  bool _needDownload = false;
  bool _isDownloading = false;
  bool _hasError = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final downloaded = await _dataService.isDataDownloaded();
    if (!mounted) return;

    if (downloaded) {
      await _fontsThenProceed();
    } else {
      setState(() {
        _isChecking = false;
        _needDownload = true;
      });
    }
  }

  Future<void> _fontsThenProceed() async {
    await _dataService.registerFonts();
    if (!mounted) return;

    Timer(const Duration(seconds: 2), () async {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final lastPage = prefs.getInt('last_read_page');
        final hasLastPage = lastPage != null && lastPage >= 1 && lastPage <= 604;
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
          if (hasLastPage) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MushafScreen(initialPage: lastPage),
              ),
            );
          }
        }
      }
    });
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _hasError = false;
      _progress = 0.0;
    });

    try {
      await _dataService.downloadAndExtract(
        url: kQuranDataUrl,
        onProgress: (received, total) {
          if (mounted && total > 0) {
            setState(() => _progress = received / total);
          }
        },
      );

      if (!mounted) return;
      await _fontsThenProceed();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final isRtl = tr.isRtl;

    return Scaffold(
      body: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Stack(
          children: [
            SizedBox.expand(
              child: Image.asset(
                'assets/images/splash.jpg',
                fit: BoxFit.cover,
              ),
            ),
            if (_isChecking)
              Center(
                child: CircularProgressIndicator(color: goldColor),
              ),
            if (_needDownload || _isDownloading || _hasError)
              Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Stack(
                  children: [
                    Center(
                      child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.jpg',
                          height: 100,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'الْقُرْآنُ الْكَرِيمُ',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: goldColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          tr.tr('data.required'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr.tr('data.size'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_isDownloading) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: Colors.white24,
                              color: goldColor,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: goldColor,
                            ),
                          ),
                        ] else if (_hasError) ...[
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.red[300]),
                          const SizedBox(height: 12),
                          Text(
                            tr.tr('data.error'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[300],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildButton(
                            label: tr.tr('data.retry'),
                            onTap: _startDownload,
                          ),
                        ] else ...[
                          _buildButton(
                            label: tr.tr('data.download'),
                            onTap: _startDownload,
                          ),

                        ],
                      ],
                    ),
                    ),
                  ),
                    Positioned(
                      top: 32,
                      left: isRtl ? null : 16,
                      right: isRtl ? 16 : null,
                      child: IconButton(
                        icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back, color: Colors.white70),
                        onPressed: () async {
                          await LocaleService.clearLocale();
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LanguageSelectionPage(),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: 220,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: goldColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 4,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


