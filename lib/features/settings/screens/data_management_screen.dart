import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../../cache/hive_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../widgets/settings_tile.dart';

// 条件导入：移动端使用 path_provider 和 dart:io
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io' if (dart.library.html) 'dart:html' as io;

/// 数据管理页面
class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  bool _isLoading = false;
  String _cacheSize = '计算中...';
  String _databaseSize = '计算中...';

  @override
  void initState() {
    super.initState();
    _calculateSizes();
  }

  Future<void> _calculateSizes() async {
    setState(() {
      _cacheSize = '计算中...';
      _databaseSize = '计算中...';
    });

    try {
      // 计算缓存大小
      final cacheSize = await _getCacheSize();
      _cacheSize = _formatBytes(cacheSize);

      // 计算数据库大小
      final dbSize = await _getDatabaseSize();
      _databaseSize = _formatBytes(dbSize);
    } catch (e) {
      _cacheSize = '计算失败';
      _databaseSize = '计算失败';
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<int> _getCacheSize() async {
    try {
      if (kIsWeb) {
        // Web端：使用 IndexedDB，无法直接计算大小
        // 返回一个估算值或提示
        return 0; // Web端暂不支持计算缓存大小
      }
      
      // 非Web平台：使用 dart:io
      if (!kIsWeb) {
        final cacheDir = await getTemporaryDirectory();
        int totalSize = 0;

        if (await cacheDir.exists()) {
          await for (final entity in cacheDir.list(recursive: true)) {
            // 在非Web平台，entity 是 dart:io 的 FileSystemEntity
            if (entity is File) {
              try {
                final length = await entity.length();
                totalSize += length;
              } catch (_) {
                // 忽略无法读取的文件
              }
            }
          }
        }

        // 计算 flutter_cache_manager 的缓存
        final defaultCacheManager = DefaultCacheManager();
        // 注意：flutter_cache_manager 没有直接获取缓存大小的方法
        // 这里只计算临时目录的大小

        return totalSize;
      }
      
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getDatabaseSize() async {
    try {
      if (kIsWeb) {
        // Web端：使用 IndexedDB，无法直接计算大小
        // 可以通过 Hive 的 API 获取，但需要额外实现
        return 0; // Web端暂不支持计算数据库大小
      }
      
      // 非Web平台：使用 dart:io
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final hiveDirPath = path.join(appDir.path, 'hive_db');
        final hiveDir = Directory(hiveDirPath);
        
        if (!await hiveDir.exists()) {
          return 0;
        }

        int totalSize = 0;
        await for (final entity in hiveDir.list(recursive: true)) {
          // 在非Web平台，entity 是 dart:io 的 FileSystemEntity
          if (entity is File) {
            try {
              final length = await entity.length();
              totalSize += length;
            } catch (_) {
              // 忽略无法读取的文件
            }
          }
        }

        return totalSize;
      }
      
      return 0;
    } catch (e) {
      return 0;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除所有缓存吗？这将删除所有缓存的图片和视频。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 清除 flutter_cache_manager 缓存
      await DefaultCacheManager().emptyCache();

      if (!kIsWeb) {
        // 清除临时目录（仅移动端）
        final cacheDir = await getTemporaryDirectory();
        if (await cacheDir.exists()) {
          await for (final entity in cacheDir.list()) {
            await entity.delete(recursive: true);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('缓存已清除'),
            backgroundColor: Colors.green,
          ),
        );
        await _calculateSizes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清除缓存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除数据库'),
        content: const Text(
          '确定要清除所有本地数据吗？这将删除所有对话记录和消息，此操作不可恢复！',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final hiveService = HiveService();
      await hiveService.clearAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('数据库已清除'),
            backgroundColor: Colors.green,
          ),
        );
        await _calculateSizes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清除数据库失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据管理'),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: _calculateSizes,
              child: ListView(
                children: [
                  // 存储信息
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '存储使用情况',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SettingsTile(
                    leadingIcon: Icons.image,
                    title: '缓存大小',
                    subtitle: kIsWeb ? 'Web端暂不支持计算' : _cacheSize,
                    trailing: kIsWeb ? null : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _calculateSizes,
                      tooltip: '刷新',
                    ),
                    onTap: null,
                  ),
                  SettingsTile(
                    leadingIcon: Icons.storage,
                    title: '数据库大小',
                    subtitle: kIsWeb ? 'Web端暂不支持计算' : _databaseSize,
                    trailing: kIsWeb ? null : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _calculateSizes,
                      tooltip: '刷新',
                    ),
                    onTap: null,
                  ),
                  // 清除操作
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '清除数据',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SettingsTile(
                    leadingIcon: Icons.delete_outline,
                    title: '清除缓存',
                    subtitle: '清除所有缓存的图片和视频',
                    onTap: _clearCache,
                  ),
                  SettingsTile(
                    leadingIcon: Icons.delete_forever,
                    title: '清除数据库',
                    subtitle: '清除所有本地对话和消息数据',
                    onTap: _clearDatabase,
                  ),
                ],
              ),
            ),
    );
  }
}
