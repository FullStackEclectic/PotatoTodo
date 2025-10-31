import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class PageHeaderWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showThemeToggle;

  const PageHeaderWidget({
    Key? key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showThemeToggle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主标题行
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // 右侧操作按钮
              if (actions != null || showThemeToggle)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...?actions,
                    if (showThemeToggle) ...[
                      if (actions != null) const SizedBox(width: 8),
                      _buildThemeToggleButton(theme),
                    ],
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggleButton(ThemeData theme) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return IconButton(
          onPressed: () {
            themeProvider.toggleThemeMode();
          },
          icon: Icon(
            themeProvider.isDarkMode 
              ? Icons.light_mode 
              : Icons.dark_mode,
            size: 20,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          tooltip: themeProvider.isDarkMode ? '切换到浅色模式' : '切换到深色模式',
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
          ),
        );
      },
    );
  }
} 