import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Web 存储适配器
/// 提供Web平台特定的存储实现
class WebStorageAdapter {
  static SharedPreferences? _prefs;

  /// 初始化存储
  static Future<void> initialize() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
    } else {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
  }

  /// 保存字符串
  static Future<bool> setString(String key, String value) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
    await initialize();
    return await _prefs?.setString(key, value) ?? false;
  }

  /// 获取字符串
  static Future<String?> getString(String key) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
    await initialize();
    return _prefs?.getString(key);
  }

  /// 保存整数
  static Future<bool> setInt(String key, int value) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
    await initialize();
    return await _prefs?.setInt(key, value) ?? false;
  }

  /// 获取整数
  static Future<int?> getInt(String key) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
    await initialize();
    return _prefs?.getInt(key);
  }

  /// 保存布尔值
  static Future<bool> setBool(String key, bool value) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
    await initialize();
    return await _prefs?.setBool(key, value) ?? false;
  }

  /// 获取布尔值
  static Future<bool?> getBool(String key) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
    await initialize();
    return _prefs?.getBool(key);
  }

  /// 保存双精度浮点数
  static Future<bool> setDouble(String key, double value) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
    await initialize();
    return await _prefs?.setDouble(key, value) ?? false;
  }

  /// 获取双精度浮点数
  static Future<double?> getDouble(String key) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
    await initialize();
    return _prefs?.getDouble(key);
  }

  /// 保存字符串列表
  static Future<bool> setStringList(String key, List<String> value) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
    await initialize();
    return await _prefs?.setStringList(key, value) ?? false;
  }

  /// 获取字符串列表
  static Future<List<String>?> getStringList(String key) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
    await initialize();
    return _prefs?.getStringList(key);
  }

  /// 删除键
  static Future<bool> remove(String key) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
    await initialize();
    return await _prefs?.remove(key) ?? false;
  }

  /// 检查键是否存在
  static Future<bool> containsKey(String key) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
    await initialize();
    return _prefs?.containsKey(key) ?? false;
  }

  /// 获取所有键
  static Future<Set<String>> getKeys() async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
    await initialize();
    return _prefs?.getKeys() ?? <String>{};
  }

  /// 清空所有
  static Future<bool> clear() async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
    await initialize();
    return await _prefs?.clear() ?? false;
  }

  /// 重新加载数据
  static Future<void> reload() async {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorageAdapter 仅支持 Web 平台');
    }
    await initialize();
    await _prefs?.reload();
  }
}
