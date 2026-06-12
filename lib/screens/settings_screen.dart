import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/backup_service.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hapticEnabled = true;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final haptic = await HapticService.isEnabled;
    final sound = SoundService().isSoundEnabled;
    if (mounted) {
      setState(() {
        _hapticEnabled = haptic;
        _soundEnabled = sound;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
      ),
      body: _buildSettingsContent(theme),
    );
  }

  Widget _buildSettingsContent(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 外观设置
          _buildSettingsSection(
            theme,
            title: '外观',
            icon: Icons.palette,
            children: [
              _buildThemeSettings(theme),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 功能设置
          _buildSettingsSection(
            theme,
            title: '功能',
            icon: Icons.tune,
            children: [
              _buildHapticSettings(theme),
              const SizedBox(height: 8),
              _buildSoundSettings(theme),
              const SizedBox(height: 8),
              _buildStatusBarTest(theme),
            ],
          ),
          
          const SizedBox(height: 24),

          // Data & Backup
          _buildSettingsSection(
            theme,
            title: '数据与安全',
            icon: Icons.security,
            children: [
              _buildDataSettings(theme),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 关于
          _buildSettingsSection(
            theme,
            title: '关于',
            icon: Icons.info,
            children: [
              _buildAboutSettings(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          // 内容
          ...children,
        ],
      ),
    );
  }

  Widget _buildThemeSettings(ThemeData theme) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          children: [
            // 主题模式
            ListTile(
              leading: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              title: const Text('主题模式'),
              subtitle: Text(
                themeProvider.isDarkMode ? '深色模式' : '浅色模式',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleThemeMode();
                },
              ),
            ),
            
            // 跟随系统
            ListTile(
              leading: Icon(
                Icons.settings_system_daydream,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              title: const Text('跟随系统'),
              subtitle: Text(
                '自动跟随系统主题设置',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              trailing: Switch(
                value: themeProvider.followSystem,
                onChanged: (value) {
                  themeProvider.setFollowSystem(value);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHapticSettings(ThemeData theme) {
    return ListTile(
      leading: Icon(
        Icons.vibration,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
      title: const Text('触觉反馈'),
      subtitle: Text(
        '操作时提供触觉反馈',
        style: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      trailing: Switch(
        value: _hapticEnabled,
        onChanged: (value) async {
          await HapticService.setEnabled(value);
          setState(() {
            _hapticEnabled = value;
          });
          if (value) {
            await HapticService.lightImpact();
          }
        },
      ),
    );
  }

  Widget _buildSoundSettings(ThemeData theme) {
    return ListTile(
      leading: Icon(
        Icons.volume_up,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
      title: const Text('音效设置'),
      subtitle: Text(
        '完成任务或升级时播放提示音',
        style: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      trailing: Switch(
        value: _soundEnabled,
        onChanged: (value) async {
          await SoundService().toggleSound(value);
          setState(() {
            _soundEnabled = value;
          });
          if (value) {
            await SoundService().playTaskComplete();
          }
        },
      ),
    );
  }

  Widget _buildStatusBarTest(ThemeData theme) {
    return ListTile(
      leading: Icon(
        Icons.phone_android,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
      title: const Text('状态栏测试'),
      subtitle: const Text('检查状态栏显示是否正确'),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      onTap: () {
        Navigator.pushNamed(context, '/status-bar-test');
      },
    );
  }

  Widget _buildDataSettings(ThemeData theme) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.download_rounded, color: theme.colorScheme.onSurface.withOpacity(0.7)),
          title: const Text('导出数据'),
          subtitle: Text('备份任务、分类和游戏化进度到文件', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          onTap: () async {
            await BackupService.exportData(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.upload_file_rounded, color: theme.colorScheme.onSurface.withOpacity(0.7)),
          title: const Text('导入数据'),
          subtitle: Text('从备份文件恢复数据 (将合并现有数据)', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          onTap: () async {
             // Show confirmation dialog
             final confirm = await showDialog<bool>(
               context: context,
               builder: (ctx) => AlertDialog(
                 title: const Text('导入备份'),
                 content: const Text('确定要导入数据吗？建议在导入前先导出当前数据以防万一。\n注意：导入过程将尝试保留现有数据，但若ID冲突可能会有意外覆盖。'),
                 actions: [
                   TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                   TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定导入')),
                 ],
               ),
             );
             
             if (confirm == true && mounted) {
               await BackupService.importData(context);
             }
          },
        ),
      ],
    );
  }

  Widget _buildAboutSettings(ThemeData theme) {
    return Column(
      children: [
        // 版本信息
        ListTile(
          leading: Icon(
            Icons.info_outline,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          title: const Text('版本'),
          subtitle: const Text('1.0.0'),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          onTap: () {
            _showAboutDialog(context);
          },
        ),
        
        // 帮助
        ListTile(
          leading: Icon(
            Icons.help_outline,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          title: const Text('帮助'),
          subtitle: const Text('使用指南和常见问题'),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          onTap: () {
            _showHelpDialog(context);
          },
        ),
        
        // 反馈
        ListTile(
          leading: Icon(
            Icons.feedback_outlined,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          title: const Text('反馈'),
          subtitle: const Text('报告问题或提出建议'),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          onTap: () {
            _showFeedbackBottomSheet(context);
          },
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用指南'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('🎯 四象限时间管理法', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('通过评估任务的“重要性”和“紧急性”，将任务划分为四个象限：'),
              Text('1. 重要且紧急：需要立即去做的高优先任务。'),
              Text('2. 重要不紧急：需要制定计划、逐步完成（个人成长核心）。'),
              Text('3. 紧急不重要：可以授权他人或快速处理的日常琐事。'),
              Text('4. 不重要不紧急：休闲消遣、无价值的事，应尽量避免。'),
              Divider(height: 24),
              Text('🍅 番茄工作法', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('1. 选择待办任务，启动番茄钟专注工作（默认25分钟）。'),
              Text('2. 保持专注，直到钟声响起。'),
              Text('3. 享受短休（默认5分钟）。'),
              Text('4. 完成4个番茄钟后，进行一次长休（15分钟）。'),
              SizedBox(height: 8),
              Text('每次完成番茄钟和任务，都会奖励经验值（XP）并解锁成就！'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackBottomSheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '问题反馈与建议',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '您的反馈对我们非常重要！请写下您遇到的问题或建议：',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '请输入反馈内容...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('反馈内容不能为空')),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('提交成功！感谢您的宝贵建议。')),
                    );
                  },
                  child: const Text('提交'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '土豆 Todo',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.check_circle_outline, size: 48),
      children: [
        const Text('一个简单高效的任务管理应用，基于四象限管理法则，帮助您合理安排时间和优先级。'),
        const SizedBox(height: 16),
        const Text('© 2024 土豆团队'),
      ],
    );
  }
}