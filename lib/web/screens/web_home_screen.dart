import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/chat/screens/conversation_list_screen.dart';
import '../../features/task/screens/task_list_screen.dart';
import '../../features/gallery/screens/gallery_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../widgets/responsive_layout.dart';

/// Web端主页面
/// 提供响应式布局，包含导航栏和侧边栏
class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({Key? key}) : super(key: key);

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      label: '对话',
      route: '/conversations',
    ),
    NavigationItem(
      icon: Icons.task_outlined,
      selectedIcon: Icons.task,
      label: '任务',
      route: '/tasks',
    ),
    NavigationItem(
      icon: Icons.photo_library_outlined,
      selectedIcon: Icons.photo_library,
      label: '图库',
      route: '/gallery',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: '设置',
      route: '/settings',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildContent() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      children: const [
        ConversationListScreen(),
        TaskListScreen(),
        GalleryScreen(),
        SettingsScreen(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final authProvider = context.watch<AuthProvider>();

    if (isDesktop || isTablet) {
      // 桌面端/平板：侧边栏布局
      return Scaffold(
        body: Row(
          children: [
            // 侧边栏
            NavigationRail(
              extended: isDesktop,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              labelType: isDesktop
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.selected,
              leading: Column(
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: isDesktop ? 24 : 20,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(height: 8),
                    Text(
                      authProvider.user?.username ?? '用户',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        await authProvider.logout();
                      },
                      tooltip: '登出',
                    ),
                  ),
                ),
              ),
              destinations: _navigationItems.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label),
                );
              }).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // 内容区域
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      );
    } else {
      // 移动端：底部导航栏
      return Scaffold(
        body: _buildContent(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: _navigationItems.map((item) {
            return NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            );
          }).toList(),
        ),
      );
    }
  }
}

/// 导航项数据模型
class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}
