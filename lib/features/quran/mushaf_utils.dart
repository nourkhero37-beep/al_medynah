import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MushafUtils {
  static Future<Map<String, int>> loadVersePageMap() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/quran_data/verses.json',
      );
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final map = <String, int>{};
      data.forEach((key, value) {
        map[key] = (value as Map<String, dynamic>)['page'] as int;
      });
      return map;
    } catch (_) {
      return {};
    }
  }

  static Future<void> sharePage({
    required GlobalKey pageCaptureKey,
    required int page,
    required String text,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        pageCaptureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      await Share.share(text);
      return;
    }
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        await Share.share(text);
        return;
      }
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/quran_page_$page.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Share.shareXFiles([
        XFile(file.path),
      ], text: text);
    } catch (_) {
      await Share.share(text);
    }
  }
}