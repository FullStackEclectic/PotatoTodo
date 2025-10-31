import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pomodoro_provider.dart';
import '../services/haptic_service.dart';

class PomodoroSettingsScreen extends StatefulWidget {
  const PomodoroSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PomodoroSettingsScreen> createState() => _PomodoroSettingsScreenState();
}

class _PomodoroSettingsScreenState extends State<PomodoroSettingsScreen> {
  late final TextEditingController _workController;
  late final TextEditingController _shortBreakController;
  late final TextEditingController _longBreakController;
  late final TextEditingController _cyclesController;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PomodoroProvider>(context, listen: false);
    
    _workController = TextEditingController(text: (provider.workDuration ~/ 60).toString());
    _shortBreakController = TextEditingController(text: (provider.shortBreakDuration ~/ 60).toString());
    _longBreakController = TextEditingController(text: (provider.longBreakDuration ~/ 60).toString());
    _cyclesController = TextEditingController(text: provider.pomodorosPerLongBreak.toString());
    
    _soundEnabled = provider.isSoundEnabled;
    _vibrationEnabled = provider.isVibrationEnabled;
  }

  @override
  void dispose() {
    _workController.dispose();
    _shortBreakController.dispose();
    _longBreakController.dispose();
    _cyclesController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    final provider = Provider.of<PomodoroProvider>(context, listen: false);
    
    // 获取数值并验证
    final workMinutes = int.tryParse(_workController.text) ?? 25;
    final shortBreakMinutes = int.tryParse(_shortBreakController.text) ?? 5;
    final longBreakMinutes = int.tryParse(_longBreakController.text) ?? 15;
    final cycles = int.tryParse(_cyclesController.text) ?? 4;
    
    // 应用设置
    provider.setWorkDuration(workMinutes);
    provider.setShortBreakDuration(shortBreakMinutes);
    provider.setLongBreakDuration(longBreakMinutes);
    provider.setPomodorosPerLongBreak(cycles);
    provider.setSoundEnabled(_soundEnabled);
    provider.setVibrationEnabled(_vibrationEnabled);
    
    await HapticService.selectionClick();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('番茄钟设置'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 工作时间设置
            _buildTimeSettingField(
              title: '工作时间 (分钟)',
              controller: _workController,
              icon: Icons.work,
            ),
            const SizedBox(height: 16),
            
            // 短休息时间设置
            _buildTimeSettingField(
              title: '短休息时间 (分钟)',
              controller: _shortBreakController,
              icon: Icons.coffee,
            ),
            const SizedBox(height: 16),
            
            // 长休息时间设置
            _buildTimeSettingField(
              title: '长休息时间 (分钟)',
              controller: _longBreakController,
              icon: Icons.hotel,
            ),
            const SizedBox(height: 16),
            
            // 循环次数设置
            _buildTimeSettingField(
              title: '长休息前工作次数',
              controller: _cyclesController,
              icon: Icons.repeat,
            ),
            const SizedBox(height: 24),
            
            // 声音和振动设置
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '通知设置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('声音提示'),
                      subtitle: const Text('阶段结束时播放声音'),
                      value: _soundEnabled,
                      onChanged: (value) {
                        setState(() {
                          _soundEnabled = value;
                        });
                      },
                      secondary: const Icon(Icons.volume_up),
                    ),
                    
                    SwitchListTile(
                      title: const Text('振动提示'),
                      subtitle: const Text('阶段结束时振动'),
                      value: _vibrationEnabled,
                      onChanged: (value) {
                        setState(() {
                          _vibrationEnabled = value;
                        });
                      },
                      secondary: const Icon(Icons.vibration),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // 保存按钮
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('保存设置'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSettingField({
    required String title,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: title,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 