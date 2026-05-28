class HadithCollection {
  final String key;
  final String name;
  final String arabicName;
  final int totalHadiths;

  HadithCollection({
    required this.key,
    required this.name,
    required this.arabicName,
    required this.totalHadiths,
  });

  factory HadithCollection.fromJson(Map<String, dynamic> json) {
    return HadithCollection(
      key: json['key'] as String,
      name: json['name'] as String,
      arabicName: json['arabic_name'] as String,
      totalHadiths: json['total_hadiths'] as int,
    );
  }
}

class Hadith {
  final String id;
  final String collection;
  final String collectionName;
  final int hadithNumber;
  final String arabic;
  final String english;
  final String grade;

  Hadith({
    required this.id,
    required this.collection,
    required this.collectionName,
    required this.hadithNumber,
    required this.arabic,
    required this.english,
    required this.grade,
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['id'] as String,
      collection: json['collection'] as String,
      collectionName: json['collection_name'] as String,
      hadithNumber: json['hadithnumber'] as int,
      arabic: json['arabic'] as String,
      english: json['english'] as String,
      grade: json['grade'] as String,
    );
  }
}
