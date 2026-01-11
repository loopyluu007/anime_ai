import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class LocalStorage {
  static SharedPreferences? _prefs;
  static bool _initialized = false;
  
  static Future<void> init() async {
    if (_initialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    } catch (e) {
      Logger.error('初始化本地存储失败: $e');
      rethrow;
    }
  }
  
  // 存储字符串
  static Future<bool> setString(String key, String value) async {
    if (!_initialized) await init();
    return await _prefs!.setString(key, value);
  }
  
  // 获取字符串
  static Future<String?> getString(String key) async {
    if (!_initialized) await init();
    return _prefs!.getString(key);
  }
  
  // 存储整数
  static Future<bool> setInt(String key, int value) async {
    if (!_initialized) await init();
    return await _prefs!.setInt(key, value);
  }
  
  // 获取整数
  static Future<int?> getInt(String key) async {
    if (!_initialized) await init();
    return _prefs!.getInt(key);
  }
  
  // 存储布尔值
  static Future<bool> setBool(String key, bool value) async {
    if (!_initialized) await init();
    return await _prefs!.setBool(key, value);
  }
  
  // 获取布尔值
  static Future<bool?> getBool(String key) async {
    if (!_initialized) await init();
    return _prefs!.getBool(key);
  }
  
  // 删除
  static Future<bool> remove(String key) async {
    if (!_initialized) await init();
    return await _prefs!.remove(key);
  }
  
  // 清空
  static Future<bool> clear() async {
    if (!_initialized) await init();
    return await _prefs!.clear();
  }
  
  // 检查是否存在
  static Future<bool> containsKey(String key) async {
    if (!_initialized) await init();
    return _prefs!.containsKey(key);
  }
}
