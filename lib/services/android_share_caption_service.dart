import 'package:flutter/services.dart';

class AndroidShareCaptionService {
  static const MethodChannel _channel = MethodChannel(
    'com.gemstone.orders/share_caption',
  );

  Future<String> getInitialSharedText() async {
    try {
      return (await _channel.invokeMethod<String>('getInitialSharedText')) ?? '';
    } on PlatformException {
      return '';
    }
  }

  Future<String> getLatestSharedText() async {
    try {
      return (await _channel.invokeMethod<String>('getLatestSharedText')) ?? '';
    } on PlatformException {
      return '';
    }
  }

  Future<void> resetSharedText() async {
    try {
      await _channel.invokeMethod<void>('resetSharedText');
    } on PlatformException {
      // Ignore; Android-only helper.
    }
  }
}
