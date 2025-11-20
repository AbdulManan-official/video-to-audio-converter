import 'dart:async';
import 'package:flutter/services.dart';

class RingtoneSetMul {
  static const MethodChannel _channel = MethodChannel('ringtone_set');

  // Check platform version
  static Future<String?> get platformVersion async {
    return await _channel.invokeMethod('getPlatformVersion');
  }

  // Check SDK version
  static Future<int?> get platformSdk async {
    return await _channel.invokeMethod('getPlatformSdk');
  }

  // Check if write permission is granted
  static Future<bool> get isWriteGranted async {
    return await _channel.invokeMethod('isWriteGranted') ?? false;
  }

  // Request write permission
  static Future<bool> requestSystemPermissions() async {
    return await _channel.invokeMethod('reqSystemPermissions') ?? false;
  }

  // Set as ringtone with optional SIM slot support
  static Future<bool> setRingtone(
      String path, {
        String? mimeType,
        int? simSlot, // 1 for SIM 1, 2 for SIM 2, null for default
      }) async {
    return await _channel.invokeMethod('setRingtone', {
      'path': path,
      'mimeType': mimeType,
      'simSlot': simSlot,
    }) ?? false;
  }

  // Set as notification sound
  static Future<bool> setNotification(String path, {String? mimeType}) async {
    return await _channel.invokeMethod('setNotification', {
      'path': path,
      'mimeType': mimeType,
    }) ?? false;
  }

  // Set as alarm
  static Future<bool> setAlarm(String path, {String? mimeType}) async {
    return await _channel.invokeMethod('setAlarm', {
      'path': path,
      'mimeType': mimeType,
    }) ?? false;
  }

  // Set multiple types at once
  static Future<bool> setMultiple(
      String path, {
        String? mimeType,
        bool isRingtone = false,
        bool isNotification = false,
        bool isAlarm = false,
      }) async {
    return await _channel.invokeMethod('setMultiple', {
      'path': path,
      'mimeType': mimeType,
      'isRingt': isRingtone,
      'isNotif': isNotification,
      'isAlarm': isAlarm,
    }) ?? false;
  }
}