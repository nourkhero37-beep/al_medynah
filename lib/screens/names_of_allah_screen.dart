import 'package:flutter/material.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';

class NamesOfAllahScreen extends StatefulWidget {
  const NamesOfAllahScreen({super.key});

  @override
  State<NamesOfAllahScreen> createState() => _NamesOfAllahScreenState();
}

class _NamesOfAllahScreenState extends State<NamesOfAllahScreen> {
  static const Color goldColor = Color(0xFFB8964E);
  static const Color darkBrown = Color(0xFF3E2A0F);

  final MuslimRepository _repo = MuslimRepository();
  List<NameOfAllah> _names = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      final names = await _repo.getNames(language: Language.ar);
      if (mounted) {
        setState(() {
          _names = names;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading names: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF8B6914),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'أسماء الله الحسنى',
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
            : _names.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text('تعذر تحميل الأسماء'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B6914),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _loadNames();
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (
                      var row = 0;
                      row < (_names.length / 6).ceil();
                      row++
                    ) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var col = 0; col < 6; col++) ...[
                              if (row * 6 + col < _names.length) ...[
                                Text(
                                  _names[row * 6 + col].name,
                                  style: const TextStyle(
                                    color: darkBrown,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (col < 5 &&
                                    row * 6 + col + 1 < _names.length)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      '✦',
                                      style: TextStyle(
                                        color: goldColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
