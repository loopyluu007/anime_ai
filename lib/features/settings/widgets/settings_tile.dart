import 'package:flutter/material.dart';

/// 设置项组件
class SettingsTile extends StatelessWidget {
  final IconData? leadingIcon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const SettingsTile({
    super.key,
    this.leadingIcon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: leadingIcon != null
              ? Icon(
                  leadingIcon,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: trailing ??
              (onTap != null
                  ? Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    )
                  : null),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

/// 带开关的设置项
class SettingsSwitchTile extends StatelessWidget {
  final IconData? leadingIcon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    this.leadingIcon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: leadingIcon != null
              ? Icon(
                  leadingIcon,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: Switch(
            value: value,
            onChanged: onChanged,
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
