import 'package:flutter/material.dart';

/// 响应式布局工具
/// 提供不同屏幕尺寸的适配功能
class ResponsiveLayout {
  /// 断点定义
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// 判断是否为移动端
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// 判断是否为平板
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// 判断是否为桌面端
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// 判断是否为大桌面端
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// 根据屏幕大小返回不同的值
  /// 
  /// [mobile] 移动端值（必需）
  /// [tablet] 平板值（可选，默认使用mobile值）
  /// [desktop] 桌面端值（可选，默认使用tablet或mobile值）
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// 响应式列数
  /// 
  /// 根据屏幕大小返回合适的列数
  static int responsiveColumns(BuildContext context) {
    if (isLargeDesktop(context)) {
      return 4;
    } else if (isDesktop(context)) {
      return 3;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 1;
    }
  }

  /// 响应式内边距
  static EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: responsiveValue(
        context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
      vertical: responsiveValue(
        context,
        mobile: 8.0,
        tablet: 16.0,
        desktop: 24.0,
      ),
    );
  }

  /// 响应式字体大小
  static double responsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      desktop: desktop ?? tablet ?? mobile * 1.5,
    );
  }

  /// 获取屏幕宽度
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 获取屏幕高度
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// 获取屏幕方向
  static Orientation orientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }

  /// 判断是否为横屏
  static bool isLandscape(BuildContext context) {
    return orientation(context) == Orientation.landscape;
  }

  /// 判断是否为竖屏
  static bool isPortrait(BuildContext context) {
    return orientation(context) == Orientation.portrait;
  }
}

/// 响应式容器
/// 自动适配不同屏幕尺寸的容器组件
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final Color? color;
  final Decoration? decoration;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
    this.color,
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 1200,
        ),
        padding: padding ?? ResponsiveLayout.responsivePadding(context),
        color: color,
        decoration: decoration,
        child: child,
      ),
    );
  }
}

/// 响应式网格视图
/// 根据屏幕大小自动调整列数
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;

  const ResponsiveGridView({
    Key? key,
    required this.children,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveLayout.responsiveColumns(context);
    
    return GridView.builder(
      padding: padding ?? ResponsiveLayout.responsivePadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// 响应式行布局
/// 在移动端垂直排列，桌面端水平排列
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const ResponsiveRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isMobile(context)) {
      // 移动端：垂直排列
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _addSpacing(children, spacing, isVertical: true),
      );
    } else {
      // 桌面端：水平排列
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _addSpacing(children, spacing, isVertical: false),
      );
    }
  }

  List<Widget> _addSpacing(
    List<Widget> widgets,
    double spacing, {
    required bool isVertical,
  }) {
    if (widgets.isEmpty) return widgets;

    final List<Widget> result = [widgets.first];
    for (int i = 1; i < widgets.length; i++) {
      result.add(
        isVertical
            ? SizedBox(height: spacing)
            : SizedBox(width: spacing),
      );
      result.add(widgets[i]);
    }
    return result;
  }
}
