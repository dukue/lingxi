import 'package:flutter/services.dart';

class ClipboardService {
  static Future<String?> getClipboardText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  static Future<void> setClipboardText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
} 