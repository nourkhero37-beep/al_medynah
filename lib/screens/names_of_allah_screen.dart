import 'package:flutter/material.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';
import 'package:al_medynah/l10n/app_localizations.dart';

class NamesOfAllahScreen extends StatefulWidget {
  const NamesOfAllahScreen({super.key});

  @override
  State<NamesOfAllahScreen> createState() => _NamesOfAllahScreenState();
}

class _NamesOfAllahScreenState extends State<NamesOfAllahScreen> {
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
      debugPrint("Error loading names: $e");
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
          backgroundColor: const Color(0xFF2493B4),
          elevation: 0,
          centerTitle: true,
          title: Text(
            AppLocalizations.of(context).tr("namesOfAllah.appBar.title"),
            style: const TextStyle(
              fontFamily: "GE SS Two",
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
                    Text(AppLocalizations.of(context).tr("namesOfAllah.error.load")),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2493B4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _loadNames();
                      },
                      child: Text(AppLocalizations.of(context).tr("namesOfAllah.retry")),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    for (var row = 0; row < (_names.length / 3).ceil(); row++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var col = 0; col < 3; col++) ...[
                              if (row * 3 + col < _names.length) ...[
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _names[row * 3 + col].name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: "GE SS Two",
                                        color: Color(0xFF1E7FA0),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                if (col < 2 && row * 3 + col + 1 < _names.length)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      "\u2726",
                                      style: TextStyle(
                                        color: const Color(0xFF2493B4)
                                            .withValues(alpha: 0.6),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ] else
                                const Spacer(),
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

