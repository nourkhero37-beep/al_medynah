import 'package:al_medynah/model/hadith_model.dart';
import 'package:al_medynah/services/hadith_api_service.dart';
import 'package:flutter/material.dart';

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
      if (mounted)
        setState(() {
          _collections = collections;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
          title: const Text(
            '\u0645\u0643\u062A\u0628\u0629 \u0627\u0644\u062D\u062F\u064A\u062B',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B6914)),
              )
            : _collections.isEmpty
            ? const Center(
                child: Text(
                  '\u062A\u0639\u0630\u0631 \u062A\u062D\u0645\u064A\u0644 \u0627\u0644\u0645\u0643\u062A\u0628\u0629',
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
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
                                style: const TextStyle(
                                  color: Color(0xFF3E2A0F),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                book.name,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${book.totalHadiths} \u062D\u062F\u064A\u062B',
                                style: const TextStyle(
                                  color: Color(0xFFB8964E),
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
  }
}

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
  int _currentNumber = 1;
  List<int> _validNumbers = [];
  int _currentIndex = 0;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

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
      setState(() {
        _isLoading = false;
        _errorMessage =
            '\u0644\u0645 \u0646\u062A\u0645\u0643\u0646 \u0645\u0646 \u0627\u0644\u0639\u062B\u0648\u0631 \u0639\u0644\u0649 \u062D\u062F\u064A\u062B. \u062D\u0627\u0648\u0644 \u0627\u0644\u0628\u062D\u062B \u0623\u0648 \u0625\u062F\u062E\u0627\u0644 \u0631\u0642\u0645.';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '\u0641\u0634\u0644 \u062A\u062D\u0645\u064A\u0644 \u0627\u0644\u0623\u062D\u0627\u062F\u064A\u062B';
        });
      }
    }
  }

  Future<void> _loadHadith(int number) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final hadith = await _api.getHadith(widget.collection.key, number);
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
          _errorMessage =
              '\u0644\u0645 \u064A\u062A\u0645 \u0627\u0644\u0639\u062B\u0648\u0631 \u0639\u0644\u0649 \u062D\u062F\u064A\u062B \u0628\u0647\u0630\u0627 \u0627\u0644\u0631\u0642\u0645';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '\u0641\u0634\u0644 \u062A\u062D\u0645\u064A\u0644 \u0627\u0644\u062D\u062F\u064A\u062B';
        });
      }
    }
  }

  Future<void> _goNext() async {
    if (_currentIndex + 1 < _validNumbers.length) {
      await _loadHadith(_validNumbers[_currentIndex + 1]);
      return;
    }
    await _loadHadith(_currentNumber + 1);
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
        _errorMessage =
            '\u0644\u0627 \u062A\u0648\u062C\u062F \u0623\u062D\u0627\u062F\u064A\u062B \u0633\u0627\u0628\u0642\u0629';
      });
    }
  }

  Future<void> _goRandom() async {
    try {
      final h = await _api.getRandomHadith();
      if (mounted) _loadHadith(h.hadithNumber);
    } catch (_) {}
  }

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });
    try {
      final results = await _api.searchHadiths(widget.collection.key, keyword);
      if (mounted)
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
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
          title: Text(
            widget.collection.arabicName,
            style: const TextStyle(
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
                decoration: InputDecoration(
                  hintText:
                      '\u0627\u0628\u062D\u062B \u0641\u064A \u0627\u0644\u0623\u062D\u0627\u062F\u064A\u062B...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFB8964E),
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          '\u062D\u062F\u064A\u062B \u0631\u0642\u0645 $num',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2A0F),
                          ),
                        ),
                        subtitle: Text(
                          hadith.length > 120 ? '...' : hadith,
                          style: const TextStyle(fontSize: 12),
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
                  child: CircularProgressIndicator(color: Color(0xFF8B6914)),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFF8B6914),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (_hadith != null) ...[
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
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
                                            color: const Color(
                                              0xFFB8964E,
                                            ).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '\u062D\u062F\u064A\u062B \u0631\u0642\u0645 ${_hadith!.hadithNumber}',
                                            style: const TextStyle(
                                              color: Color(0xFFB8964E),
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        _hadith!.arabic,
                                        style: const TextStyle(
                                          color: Color(0xFF3E2A0F),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          height: 1.6,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        height: 1,
                                        color: Colors.grey[200],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _hadith!.english,
                                        style: TextStyle(
                                          color: Colors.grey[700],
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
                                            color: const Color(
                                              0xFF3E2A0F,
                                            ).withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '\u0627\u0644\u062D\u0643\u0645: ',
                                            style: const TextStyle(
                                              color: Color(0xFF3E2A0F),
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
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: Colors.grey[600],
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
                                      decoration: InputDecoration(
                                        hintText:
                                            '\u0631\u0642\u0645 \u0627\u0644\u062D\u062F\u064A\u062B',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                      backgroundColor: const Color(0xFF8B6914),
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
                                    child: const Text(
                                      '\u0627\u0630\u0647\u0628',
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
                                    '\u0627\u0644\u0633\u0627\u0628\u0642',
                                    _goPrev,
                                  ),
                                  _navButton(
                                    Icons.shuffle_rounded,
                                    '\u0639\u0634\u0648\u0627\u0626\u064A',
                                    _goRandom,
                                  ),
                                  _navButton(
                                    Icons.skip_next_rounded,
                                    '\u0627\u0644\u062A\u0627\u0644\u064A',
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
  }

  Widget _navButton(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3E2A0F),
        elevation: 0,
        side: BorderSide(color: const Color(0xFFB8964E).withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}