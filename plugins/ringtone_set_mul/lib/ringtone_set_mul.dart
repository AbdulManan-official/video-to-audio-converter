import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:ringtone_set_mul/src/setter_functions.dart';

/// A class for setting ringtones, notifications, alarms.
class RingtoneSet {
  static const MethodChannel _channel = const MethodChannel('ringtone_set');

  /// Android version.
  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// Android SDK version code.
  static Future<int> get platformSdk async {
    final int sdk = await _channel.invokeMethod('getPlatformSdk');
    return sdk;
  }

  ///多选!!!
  static Future<bool> setMultipleFile(File file,
      {bool isNotification = false,
      bool isRingtone = false,
      bool isAlarm = false}) async {
    return setMultipleFromFile(
        file: file,
        action: 'setMultiple',
        isNotification: isNotification,
        isRingtone: isRingtone,
        isAlarm: isAlarm);
  }

  ///多选
  static Future<bool> setMultipleAsset(String asset,
      {bool isNotification = false,
      bool isRingtone = false,
      bool isAlarm = false}) async {
    return setMultipleFromAsset(
        asset: asset,
        action: 'setMultiple',
        isNotification: isNotification,
        isRingtone: isRingtone,
        isAlarm: isAlarm);
  }

  /// Status of the `WRITE_SETTINGS` permission.
  ///
  /// Returns `true` if the permission has been granted.
  /// On Android 5.1(SDK 22) and older always returns `true`.
  static Future<bool>  isWriteSettingsGranted() async {
    final bool granted = await _channel.invokeMethod('isWriteGranted');
    return granted;
  }

  static Future<bool>  reqSystemPermissions() async {
    _channel.invokeMethod('reqSystemPermissions');
    return true;
  }

  /// Sets ringtone from asset.
  static Future<bool> setRingtone(String asset) async {
    return setFromAsset(
      asset: asset,
      action: 'setRingtone',
    );
  }

  /// Sets ringtone from network URL.
  static Future<bool> setRingtoneFromNetwork(String url) async {
    return setFromNetwork(
      url: url,
      action: 'setRingtone',
    );
  }

  /// Sets ringtone from file.
  static Future<bool> setRingtoneFromFile(File file) async {
    return setFromFile(
      file: file,
      action: 'setRingtone',
    );
  }

  /// Sets notification from asset path.
  static Future<bool> setNotification(String asset) async {
    return setFromAsset(
      asset: asset,
      action: 'setNotification',
    );
  }

  /// Sets notification from network URL.
  static Future<bool> setNotificationFromNetwork(String url) async {
    return setFromNetwork(
      url: url,
      action: 'setNotification',
    );
  }

  /// Sets notification from file.
  static Future<bool> setNotificationFromFile(File file) async {
    return setFromFile(
      file: file,
      action: 'setNotification',
    );
  }

  /// Sets alarm from asset path.
  static Future<bool> setAlarm(String asset) async {
    return setFromAsset(
      asset: asset,
      action: 'setAlarm',
    );
  }

  /// Sets alarm from network URL.
  static Future<bool> setAlarmFromNetwork(String url) async {
    return setFromNetwork(
      url: url,
      action: 'setAlarm',
    );
  }

  /// Sets alarm from file.
  static Future<bool> setAlarmFromFile(File file) async {
    return setFromFile(
      file: file,
      action: 'setAlarm',
    );
  }
}
