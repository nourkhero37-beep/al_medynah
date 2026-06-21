import 'package:al_medynah/model/hadith_model.dart';
import 'package:al_medynah/services/hadith_api_service.dart';
import 'package:flutter/material.dart';
import 'package:al_medynah/l10n/app_localizations.dart';
import 'package:al_medynah/main.dart';
class HadithBrowserScreen extends StatefulWidget {
  final HadithCollection collection;
  const HadithBrowserScreen({super.key, required this.collection});

  @override
  State<HadithBrowserScreen> createState() => _HadithBrowserScreenState();
}

class _HadithBrowserScreenState extends State<HadithBrowserScreen> {
  final HadithApiService _api = HadithApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _numberCtrl = TextEditingController();

  Hadith? _hadith;
  bool _isLoading = true;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  String? _errorMessage;

  int _currentNumber = 1;
  List<int> _validNumbers = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFirstHadith();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHadith(int number) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final hadith = await _api.getHadith(
        widget.collection.key,
        number,
      );
      if (!mounted) return;
      if (hadith != null) {
        int idx = _validNumbers.indexOf(number);
        if (idx < 0) {
          _validNumbers.add(number);
          _validNumbers.sort();
          idx = _validNumbers.indexOf(number);
        }
        setState(() {
          _hadith = hadith;
          _currentNumber = number;
          _currentIndex = idx;
          _isLoading = false;
          _searchResults = [];
        });
      } else {
        setState(() {
          _hadith = null;
          _currentNumber = number;
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context).tr('hadith.error.numberNotFound');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context).tr('hadith.error.loadHadith');
        });
      }
    }
  }

  Future<void> _loadFirstHadith() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final validNumbers = await _api.getValidHadithNumbers(
        widget.collection.key,
      );
      if (!mounted) return;
      if (validNumbers.isNotEmpty) {
        _validNumbers = validNumbers;
        _currentIndex = 0;
        await _loadHadith(validNumbers.first);
        return;
      }
      final hadith = await _api.getHadith(widget.collection.key, 1);
      if (mounted && hadith != null) {
        _validNumbers = [1];
        _currentIndex = 0;
        setState(() {
          _hadith = hadith;
          _currentNumber = 1;
          _isLoading = false;
        });
        return;
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context).tr('hadith.error.notFound');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context).tr('hadith.error.loadFail');
        });
      }
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });
    try {
      final results = await _api.searchHadiths(
        widget.collection.key,
        query.trim(),
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _goPrev() async {
    if (_currentIndex - 1 >= 0) {
      await _loadHadith(_validNumbers[_currentIndex - 1]);
      return;
    }
    if (_currentNumber - 1 >= 1) {
      await _loadHadith(_currentNumber - 1);
    } else {
      setState(() {
        _hadith = null;
        _errorMessage = AppLocalizations.of(context).tr('hadith.error.noPrevious');
      });
    }
  }

  Future<void> _goNext() async {
    if (_currentIndex + 1 < _validNumbers.length) {
      await _loadHadith(_validNumbers[_currentIndex + 1]);
      return;
    }
    await _loadHadith(_currentNumber + 1);
  }

  Future<void> _goRandom() async {
    try {
      final h = await _api.getRandomHadith();
      if (mounted) { _loadHadith(h.hadithNumber); }
    } catch (_) {}
  }

  Widget _navButton(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2493B4),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
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
                widget.collection.arabicName,
                style: const TextStyle(
                  fontFamily: 'GE SS Two',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(color: isDark ? Colors.white : null),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).tr('hadith.search.hint'),
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : null),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF333333) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? const Color(0xFFD4B88A) : const Color(0xFF2493B4),
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.grey),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (v) => _search(v),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, i) {
                        final item = _searchResults[i];
                        final hadith = item['text'] as String;
                        final num = item['hadithnumber'] as int;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isDark ? const Color(0xFF333333) : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              AppLocalizations.of(context).tr('hadith.search.result', {'number': num.toString()}),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF4DD0E1) : const Color(0xFF1E7FA0),
                              ),
                            ),
                            subtitle: Text(
                              hadith.length > 120 ? '...' : hadith,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : null,
                              ),
                            ),
                            onTap: () => _loadHadith(num),
                          ),
                        );
                      },
                    ),
                  )
                else if (_isSearching)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF2493B4)),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Color(0xFF2493B4),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  if (_hadith != null) ...[
                                    Container(
                                      width: double.infinity,
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
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2493B4).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                AppLocalizations.of(context).tr('hadith.detail.number', {'number': _hadith!.hadithNumber.toString()}),
                                                style: const TextStyle(
                                                  color: Color(0xFF2493B4),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            _hadith!.arabic,
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFFF0F0F0) : const Color(0xFF3E2A0F),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              height: 1.6,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            height: 1,
                                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _hadith!.english,
                                            style: TextStyle(
                                              color: isDark ? Colors.white70 : Colors.grey[700],
                                              fontSize: 14,
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          if (_hadith!.grade.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFFD4B88A).withValues(alpha: 0.12)
                                                    : const Color(0xFF3E2A0F).withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                AppLocalizations.of(context).tr('hadith.grade'),
                                                style: TextStyle(
                                                  color: isDark ? const Color(0xFFD4B88A) : const Color(0xFF3E2A0F),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    if (_errorMessage != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 24,
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.info_outline_rounded,
                                              size: 40,
                                              color: isDark ? Colors.white38 : Colors.grey[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _errorMessage!,
                                              style: TextStyle(
                                                color: isDark ? Colors.white70 : Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _numberCtrl,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: isDark ? Colors.white : null),
                                          decoration: InputDecoration(
                                            hintText: AppLocalizations.of(context).tr('hadith.input.hint'),
                                            hintStyle: TextStyle(color: isDark ? Colors.white38 : null),
                                            filled: true,
                                            fillColor: isDark ? const Color(0xFF333333) : Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 12,
                                                ),
                                          ),
                                          onSubmitted: (v) {
                                            final n = int.tryParse(v);
                                            if (n != null && n > 0) _loadHadith(n);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2493B4),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: () {
                                          final n = int.tryParse(_numberCtrl.text);
                                          if (n != null && n > 0) _loadHadith(n);
                                        },
                                        child: Text(
                                          AppLocalizations.of(context).tr('hadith.button.go'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _navButton(
                                        Icons.skip_previous_rounded,
                                        AppLocalizations.of(context).tr('hadith.button.prev'),
                                        _goPrev,
                                      ),
                                      _navButton(
                                        Icons.shuffle_rounded,
                                        AppLocalizations.of(context).tr('hadith.button.random'),
                                        _goRandom,
                                      ),
                                      _navButton(
                                        Icons.skip_next_rounded,
                                        AppLocalizations.of(context).tr('hadith.button.next'),
                                        _goNext,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
