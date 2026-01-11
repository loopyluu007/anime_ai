import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../widgets/responsive_layout.dart';

/// Web端应用栏
/// 提供响应式的顶部导航栏
class WebAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const WebAppBar({
    Key? key,
    this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final authProvider = context.watch<AuthProvider>();

    return AppBar(
      title: title != null
          ? Text(title!)
          : Row(
              children: [
                Icon(
                  Icons.movie_creation,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text('AI漫导'),
              ],
            ),
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: [
        ...?actions,
        // 用户信息（桌面端显示）
        if (isDesktop && authProvider.user != null) ...[
          const SizedBox(width: 8),
          Chip(
            avatar: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                authProvider.user!.username[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            label: Text(authProvider.user!.username),
          ),
          const SizedBox(width: 8),
        ],
        // 登出按钮
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await authProvider.logout();
          },
          tooltip: '登出',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
