import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 关于页面
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  String get _version => '1.0.0';
  String get _buildNumber => '1';

  static Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开链接: $url')),
        );
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: ListView(
        children: [
          // Logo 和应用名称
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.movie_creation,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'AI漫导',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '版本 $_version (Build $_buildNumber)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // 应用描述
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'AI漫导是一个AI智能体驱动的短剧制作平台，'
              '帮助用户将创意想法转化为精彩的视频内容。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(),
          // 链接
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('开源协议'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchURL(context, 'https://github.com/your-repo'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('隐私政策'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchURL(context, 'https://your-domain.com/privacy'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('用户协议'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchURL(context, 'https://your-domain.com/terms'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('反馈问题'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchURL(context, 'https://github.com/your-repo/issues'),
          ),
          const Divider(),
          // 版权信息
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '© 2024 AI漫导\n保留所有权利',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
