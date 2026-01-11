import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage.dart';
import '../../../shared/themes/app_theme.dart';

/// 主题模式
enum AppThemeMode {
  light,
  dark,
  system,
}

/// 语言设置
enum AppLanguage {
  zh,
  en,
  system,
}

/// 设置 Provider
class SettingsProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _notificationEnabledKey = 'notification_enabled';
  static const String _autoPlayVideoKey = 'auto_play_video';
  static const String _cacheEnabledKey = 'cache_enabled';

  AppThemeMode _themeMode = AppThemeMode.system;
  AppLanguage _language = AppLanguage.system;
  bool _notificationEnabled = true;
  bool _autoPlayVideo = false;
  bool _cacheEnabled = true;

  bool _isInitialized = false;

  /// 主题模式
  AppThemeMode get themeMode => _themeMode;

  /// 语言设置
  AppLanguage get language => _language;

  /// 通知是否启用
  bool get notificationEnabled => _notificationEnabled;

  /// 自动播放视频
  bool get autoPlayVideo => _autoPlayVideo;

  /// 缓存是否启用
  bool get cacheEnabled => _cacheEnabled;

  /// 初始化设置
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 加载主题设置
      final themeModeIndex = await LocalStorage.getInt(_themeModeKey);
      if (themeModeIndex != null) {
        _themeMode = AppThemeMode.values[themeModeIndex];
      }

      // 加载语言设置
      final languageIndex = await LocalStorage.getInt(_languageKey);
      if (languageIndex != null) {
        _language = AppLanguage.values[languageIndex];
      }

      // 加载通知设置
      _notificationEnabled = await LocalStorage.getBool(_notificationEnabledKey) ?? true;

      // 加载自动播放设置
      _autoPlayVideo = await LocalStorage.getBool(_autoPlayVideoKey) ?? false;

      // 加载缓存设置
      _cacheEnabled = await LocalStorage.getBool(_cacheEnabledKey) ?? true;

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('加载设置失败: $e');
    }
  }

  /// 设置主题模式
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await LocalStorage.setInt(_themeModeKey, mode.index);
    notifyListeners();
  }

  /// 设置语言
  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;

    _language = language;
    await LocalStorage.setInt(_languageKey, language.index);
    notifyListeners();
  }

  /// 设置通知启用状态
  Future<void> setNotificationEnabled(bool enabled) async {
    if (_notificationEnabled == enabled) return;

    _notificationEnabled = enabled;
    await LocalStorage.setBool(_notificationEnabledKey, enabled);
    notifyListeners();
  }

  /// 设置自动播放视频
  Future<void> setAutoPlayVideo(bool enabled) async {
    if (_autoPlayVideo == enabled) return;

    _autoPlayVideo = enabled;
    await LocalStorage.setBool(_autoPlayVideoKey, enabled);
    notifyListeners();
  }

  /// 设置缓存启用状态
  Future<void> setCacheEnabled(bool enabled) async {
    if (_cacheEnabled == enabled) return;

    _cacheEnabled = enabled;
    await LocalStorage.setBool(_cacheEnabledKey, enabled);
    notifyListeners();
  }

  /// 获取当前主题
  ThemeData getCurrentTheme() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return AppTheme.lightTheme;
      case AppThemeMode.dark:
        return AppTheme.darkTheme;
      case AppThemeMode.system:
        return AppTheme.lightTheme; // 默认浅色主题
    }
  }

  /// 获取主题模式对应的 Material ThemeMode
  ThemeMode getMaterialThemeMode() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
