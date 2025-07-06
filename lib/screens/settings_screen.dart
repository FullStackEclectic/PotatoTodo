import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';
import '../services/data_export_service.dart';
import '../services/haptic_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isHapticEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isHapticEnabled = prefs.getBool('haptic_enabled') ?? true;

    setState(() {
      _isHapticEnabled = isHapticEnabled;
    });

    if (mounted) {
      HapticService.setEnabled(isHapticEnabled);
    }
    
    debugPrint('[SettingsScreen] 加载设置：hapticEnabled=$isHapticEnabled');
  }

  Future<void> _toggleHapticFeedback(bool value) async {
    await HapticService.setEnabled(value);
    setState(() {
      _isHapticEnabled = value;
    });
    debugPrint('[SettingsScreen] 切换触觉反馈：$value');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    debugPrint('[SettingsScreen] 构建设置界面：darkMode=${themeProvider.isDarkMode}, followSystem=${themeProvider.followSystem}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 主题设置
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '主题设置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('深色模式'),
                  subtitle: Text(themeProvider.followSystem 
                    ? '当前跟随系统，无法手动切换' 
                    : '手动切换深色/浅色模式'),
                  value: themeProvider.isDarkMode,
                  onChanged: themeProvider.followSystem ? null : (value) {
                    debugPrint('[SettingsScreen] 切换深色模式：$value');
                    themeProvider.setDarkMode(value);
                    HapticService.selectionClick();
                  },
                ),
                SwitchListTile(
                  title: const Text('跟随系统'),
                  subtitle: const Text('自动跟随系统深色/浅色模式'),
                  value: themeProvider.followSystem,
                  onChanged: (value) {
                    debugPrint('[SettingsScreen] 切换跟随系统：$value');
                    themeProvider.setFollowSystem(value);
                    HapticService.selectionClick();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          
          // 触觉反馈设置
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '触觉反馈',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('启用触觉反馈'),
                  subtitle: const Text('为操作提供触觉反馈'),
                  value: _isHapticEnabled,
                  onChanged: (value) {
                    _toggleHapticFeedback(value);
                    HapticService.selectionClick();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          
          const Divider(),
          
          // 数据管理
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '数据管理',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('导出数据'),
                  subtitle: const Text('导出所有任务和分类数据'),
                  trailing: const Icon(Icons.upload_file),
                  onTap: () async {
                    HapticService.mediumImpact();
                    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
                    
                    final exportService = DataExportService(
                      taskProvider: taskProvider,
                      categoryProvider: categoryProvider,
                    );
                    
                    try {
                      await exportService.exportAndShare();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('数据导出成功')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('导出失败: $e')),
                        );
                      }
                    }
                  },
                ),
                
                ListTile(
                  title: const Text('导入数据'),
                  subtitle: const Text('从文件导入任务和分类数据'),
                  trailing: const Icon(Icons.download),
                  onTap: () async {
                    HapticService.mediumImpact();
                    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
                    
                    final exportService = DataExportService(
                      taskProvider: taskProvider,
                      categoryProvider: categoryProvider,
                    );
                    
                    try {
                      await exportService.importFromFile();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('数据导入成功')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('导入失败: $e')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          
          // 关于
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '关于',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('关于土豆Todo'),
                  trailing: const Icon(Icons.info_outline),
                  onTap: () {
                    HapticService.lightImpact();
                    showAboutDialog(
                      context: context,
                      applicationName: '土豆Todo',
                      applicationVersion: '1.0.0',
                      applicationIcon: const FlutterLogo(size: 50),
                      children: [
                        const Text('一个简单而强大的待办事项管理应用'),
                        const SizedBox(height: 16),
                        const Text('© 2024 土豆Todo团队'),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 