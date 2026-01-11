import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';

/// Hive Web 适配器
/// 
/// 提供Web平台的Hive数据库初始化功能
/// Web端使用IndexedDB作为底层存储
class HiveWebAdapter {
  static bool _initialized = false;

  /// 初始化 Hive（Web 端）
  /// 
  /// Web端会自动使用IndexedDB作为存储后端
  /// 此方法可以安全地多次调用，只会初始化一次
  static Future<void> initialize() async {
    if (!kIsWeb) {
      throw UnsupportedError('HiveWebAdapter 仅支持 Web 平台');
    }

    if (_initialized) {
      return;
    }

    // Web 端：直接初始化，使用 IndexedDB
    await Hive.initFlutter();
    _initialized = true;
  }

  /// 打开 Box
  /// 
  /// [name] Box名称
  /// 返回打开的Box实例
  static Future<Box<T>> openBox<T>(String name) async {
    await initialize();
    return await Hive.openBox<T>(name);
  }

  /// 打开懒加载 Box
  /// 
  /// [name] Box名称
  /// 返回打开的懒加载Box实例
  /// 懒加载Box在首次访问数据时才从磁盘加载
  static Future<LazyBox<T>> openLazyBox<T>(String name) async {
    await initialize();
    return await Hive.openLazyBox<T>(name);
  }

  /// 删除 Box
  /// 
  /// [name] Box名称
  /// 返回是否删除成功
  static Future<bool> deleteBox(String name) async {
    await initialize();
    return await Hive.deleteBoxFromDisk(name);
  }

  /// 检查 Box 是否存在
  /// 
  /// [name] Box名称
  /// 返回Box是否存在
  static Future<bool> boxExists(String name) async {
    await initialize();
    return await Hive.boxExists(name);
  }

  /// 关闭所有打开的 Box
  static Future<void> closeAllBoxes() async {
    await Hive.close();
    _initialized = false;
  }
}
