class RecitersModel {
  final int id;
  final String nameArabic;
  final String serverUrl;
  final String rewaya;

  const RecitersModel({
    required this.id,
    required this.nameArabic,
    required this.serverUrl,
    required this.rewaya,
  });

  factory RecitersModel.fromJson(Map<String, dynamic> json) {
    // كل قارئ عنده moshaf (قراءات متعددة)
    final moshaf = (json['moshaf'] as List<dynamic>).first;
    return RecitersModel(
      id: moshaf['id'] as int,
      nameArabic: json['name'] as String,
      serverUrl: moshaf['server'] as String,
      rewaya: moshaf['rewaya'] as String,
    );
  }
}
