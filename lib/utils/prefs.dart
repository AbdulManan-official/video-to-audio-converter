import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static late SharedPreferences _preferences;

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static Future<void> setBool(String key, bool value) async {
    await _preferences.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _preferences.getBool(key);
  }

  static Future<void> setString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  static String? getString(String key) {
    return _preferences.getString(key);
  }
// prefs.dart (Add this method)

  static Future<void> remove(String key) async {
    await _preferences.remove(key);
  }
  // static Future<void> setFileSystemEntityList(
  //     String key, List<FileSystemEntity> value) async {
  //   List<String> paths = value.map((e) => e.path).toList();
  //   await _preferences.setStringList(key, paths);
  // }

  // static List<FileSystemEntity>? getFileSystemEntityList(String key) {
  //   List<String>? paths = _preferences.getStringList(key);
  //   if (paths == null) return null;
  //   return paths.map((path) => File(path)).toList();
  // }
}
