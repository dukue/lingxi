import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class FloatingWindowService {
  static const platform = MethodChannel('com.example.lingxi/floating_window');
  static final ValueNotifier<bool> isShowingNotifier = ValueNotifier(false);

  static bool get isShowing => isShowingNotifier.value;

  static set isShowing(bool value) {
    isShowingNotifier.value = value;
  }

  static Future<bool> checkFloatingWindowStatus() async {
    try {
      final bool isShowing = await platform.invokeMethod('checkFloatingWindowStatus');
      isShowingNotifier.value = isShowing;
      return isShowing;
    } on PlatformException catch (e) {
      print("Failed to check floating window status: ${e.message}");
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await platform.invokeMethod('requestFloatingWindowPermission');
    } on PlatformException catch (e) {
      print("Failed to request permission: ${e.message}");
    }
  }

  static Future<void> show() async {
    try {
      await platform.invokeMethod('showFloatingWindow');
      isShowingNotifier.value = true;
    } on PlatformException catch (e) {
      print("Failed to show floating window: ${e.message}");
    }
  }

  static Future<void> hide() async {
    try {
      await platform.invokeMethod('hideFloatingWindow');
      isShowingNotifier.value = false;
    } on PlatformException catch (e) {
      print("Failed to hide floating window: ${e.message}");
    }
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onFloatingWindowClosed') {
      isShowing = false;
    }
  }

  static void initialize() {
    platform.setMethodCallHandler(_handleMethodCall);
  }

  static void dispose() {
    platform.setMethodCallHandler(null);
  }
} 