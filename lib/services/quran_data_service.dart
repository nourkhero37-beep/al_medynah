import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const String kQuranDataUrl = 'https://github.com/nourkhero37-beep/al_medynah/releases/download/v1.0.0/quran_data.zip';

Map<String, dynamic> _parsePageJson(String json) => jsonDecode(json) as Map<String, dynamic>;

class QuranDataService {
  static final QuranDataService _instance = QuranDataService._internal();
  factory QuranDataService() => _instance;
  QuranDataService._internal();

  final Dio _dio = Dio();
  String? _basePath;

  Future<String> get _dataDir async {
    if (_basePath != null) return _basePath!;
    final docDir = await getApplicationDocumentsDirectory();
    _basePath = '${docDir.path}/quran_data';
    return _basePath!;
  }

  Future<String> _getPagePath(int page) async {
    final dir = await _dataDir;
    return '$dir/pages/${page.toString().padLeft(3, '0')}.json';
  }

  Future<bool> isDataDownloaded() async {
    final dir = await _dataDir;
    return File('$dir/pages/001.json').existsSync();
  }

  Future<void> downloadAndExtract({
    required String url,
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await _dataDir;
    final zipPath = '$dir/temp.zip';

    Directory(dir).createSync(recursive: true);

    await _dio.download(
      url,
      zipPath,
      options: Options(receiveTimeout: const Duration(seconds: 60)),
      onReceiveProgress: onProgress,
    );

    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final entry in archive) {
      if (entry.isFile) {
        final name = entry.name.replaceAll('\\', '/');
        final outPath = '$dir/$name';
        final outFile = File(outPath);
        outFile.createSync(recursive: true);
        await outFile.writeAsBytes(entry.content);
      }
    }

    await File(zipPath).delete();
  }

  Future<void> registerFonts() async {
    final dir = await _dataDir;
    final fontDir = Directory('$dir/fonts');
    if (!fontDir.existsSync()) return;

    final fontFiles = fontDir.listSync().whereType<File>().toList();

    await Future.wait(fontFiles.map((file) async {
      final name = file.uri.pathSegments.last;
      final family = name.replaceAll(RegExp(r'_W\.ttf$|\.ttf$'), '');
      final bytes = await file.readAsBytes();
      final byteData = ByteData.sublistView(bytes);
      final loader = FontLoader(family);
      loader.addFont(Future.value(byteData));
      await loader.load();
    }));
  }

  Future<Map<String, dynamic>> loadPage(int page) async {
    final path = await _getPagePath(page);
    final jsonString = await File(path).readAsString();
    return compute(_parsePageJson, jsonString);
  }

  Future<String> loadPageRaw(int page) async {
    final path = await _getPagePath(page);
    return File(path).readAsString();
  }

  Future<void> deleteData() async {
    final dir = await _dataDir;
    final dataDir = Directory(dir);
    if (dataDir.existsSync()) {
      await dataDir.delete(recursive: true);
    }
  }
}
