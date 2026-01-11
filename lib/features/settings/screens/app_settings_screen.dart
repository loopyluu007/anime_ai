import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_switch_tile.dart';

/// 应用设置页面
class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('应用设置'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            children: [
              // 主题设置
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '外观',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              SettingsTile(
                leadingIcon: Icons.palette,
                title: '主题模式',
                subtitle: _getThemeModeText(settingsProvider.themeMode),
                onTap: () => _showThemeModeDialog(context, settingsProvider),
              ),
              // 语言设置
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '语言',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              SettingsTile(
                leadingIcon: Icons.language,
                title: '语言',
                subtitle: _getLanguageText(settingsProvider.language),
                onTap: () => _showLanguageDialog(context, settingsProvider),
              ),
              // 通知设置
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '通知',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              SettingsSwitchTile(
                leadingIcon: Icons.notifications,
                title: '启用通知',
                subtitle: '接收应用通知和提醒',
                value: settingsProvider.notificationEnabled,
                onChanged: (value) {
                  settingsProvider.setNotificationEnabled(value);
                },
              ),
              // 媒体设置
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '媒体',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              SettingsSwitchTile(
                leadingIcon: Icons.play_circle_outline,
                title: '自动播放视频',
                subtitle: '进入页面时自动播放视频',
                value: settingsProvider.autoPlayVideo,
                onChanged: (value) {
                  settingsProvider.setAutoPlayVideo(value);
                },
              ),
              // 缓存设置
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '缓存',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              SettingsSwitchTile(
                leadingIcon: Icons.storage,
                title: '启用缓存',
                subtitle: '缓存图片和视频以提升加载速度',
                value: settingsProvider.cacheEnabled,
                onChanged: (value) {
                  settingsProvider.setCacheEnabled(value);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  String _getLanguageText(AppLanguage language) {
    switch (language) {
      case AppLanguage.zh:
        return '简体中文';
      case AppLanguage.en:
        return 'English';
      case AppLanguage.system:
        return '跟随系统';
    }
  }

  void _showThemeModeDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('浅色'),
              value: ThemeMode.light,
              groupValue: settingsProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('深色'),
              value: ThemeMode.dark,
              groupValue: settingsProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: settingsProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择语言'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AppLanguage>(
              title: const Text('简体中文'),
              value: AppLanguage.zh,
              groupValue: settingsProvider.language,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setLanguage(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<AppLanguage>(
              title: const Text('English'),
              value: AppLanguage.en,
              groupValue: settingsProvider.language,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setLanguage(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<AppLanguage>(
              title: const Text('跟随系统'),
              value: AppLanguage.system,
              groupValue: settingsProvider.language,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setLanguage(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
