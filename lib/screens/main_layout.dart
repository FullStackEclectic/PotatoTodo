import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 导入键盘服务
import 'package:potato_todo/utils/platform_util.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../models/task.dart';
import '../models/quadrant_type.dart';
import 'home_screen.dart';
import 'quadrant_view_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'achievements_screen.dart';
import 'calendar_screen.dart';
import '../constants/quadrant_constants.dart'; // 导入象限常量
import 'pomodoro_screen.dart'; // 导入番茄钟屏幕
import '../services/haptic_service.dart'; // 导入触觉服务
import '../widgets/category_panel.dart'; // 导入新的 CategoryPanel
import '../widgets/collapsible_sidebar.dart'; // 导入新的 Sidebar
import '../services/smart_input_parser.dart'; // Import Parser
import '../providers/gamification_provider.dart'; // Import Gamification
import 'package:flutter/scheduler.dart'; // For post frame callback
import 'package:quick_actions/quick_actions.dart'; // Quick Actions

// --- 定义 Intents ---
class NewTaskIntent extends Intent {}
class ToggleSearchIntent extends Intent {}
class SwitchTabIntent extends Intent {
  final int tabIndex;
  SwitchTabIntent(this.tabIndex);
}

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int? _lastLevel; // Track level for updates
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_currentIndex == 0) {
        Provider.of<TaskProvider>(context, listen: false).setSearchQuery(_searchController.text);
      }
    });

    if (PlatformUtil.isMobile) {
      const QuickActions quickActions = QuickActions();
      quickActions.initialize((String shortcutType) {
        if (shortcutType == 'action_add_task') {
          // Delay slightly to ensure context is ready or frame
           SchedulerBinding.instance.addPostFrameCallback((_) {
             _addTask();
           });
        }
        if (shortcutType == 'action_search') {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!_isSearching) _handleToggleSearch();
          });
        }
      });

      quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: 'action_add_task', localizedTitle: '新建任务', icon: 'add'),
        const ShortcutItem(type: 'action_search', localizedTitle: '搜索任务', icon: 'search'),
      ]);
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  List<Widget> get _pages => [
    HomeScreen(scaffoldKey: _scaffoldKey), // Reverted to simple HomeScreen
    const QuadrantViewScreen(initialQuadrant: QuadrantType.importantUrgent, showAsGrid: true),
    const PomodoroScreen(),
    const CalendarScreen(),
    const StatisticsScreen(),
  ];
  
  final List<String> _titles = ['任务', '四象限', '专注', '日历', '统计'];
  
  final List<IconData> _icons = [
    Icons.task,
    Icons.grid_view,
    Icons.timer,
    Icons.calendar_today,
    Icons.analytics,
  ];
  
  void _addTask() {
    _showQuickAddTaskDialog(context);
  }

  void _handleNewTask() {
    _addTask();
  }

  void _handleToggleSearch() {
    _toggleSearch();
    if (_isSearching) {
      _searchFocusNode.requestFocus();
    } else {
      _searchFocusNode.unfocus();
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        Provider.of<TaskProvider>(context, listen: false).setSearchQuery(null);
        _searchFocusNode.unfocus();
      }
    });
  }

  void _handleSwitchTab(int index) {
    if (_currentIndex != index) {
      if (_isSearching) {
        _toggleSearch();
      }
      Provider.of<TaskProvider>(context, listen: false).setSelectedTask(null);
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to gamification changes for Level Up event
    final gameProvider = Provider.of<GamificationProvider>(context);
    if (_lastLevel != null && gameProvider.level > _lastLevel!) {
      // Create a local var to capture the new level, though gameProvider.level is fine
      final newLevel = gameProvider.level;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _showLevelUpDialog(newLevel);
      });
    }
    _lastLevel = gameProvider.level;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) { // Using a wider breakpoint for the sidebar
          return _buildMobileLayout(context);
        } else {
          return _buildDesktopLayout(context);
        }
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final shortcuts = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.keyN): NewTaskIntent(),
      LogicalKeySet(LogicalKeyboardKey.slash): ToggleSearchIntent(),
      LogicalKeySet(LogicalKeyboardKey.digit1): SwitchTabIntent(0),
      LogicalKeySet(LogicalKeyboardKey.digit2): SwitchTabIntent(1),
      LogicalKeySet(LogicalKeyboardKey.digit3): SwitchTabIntent(2),
      LogicalKeySet(LogicalKeyboardKey.digit4): SwitchTabIntent(3),
    };

    final actions = <Type, Action<Intent>>{
      NewTaskIntent: CallbackAction<NewTaskIntent>(onInvoke: (intent) => _handleNewTask()),
      ToggleSearchIntent: CallbackAction<ToggleSearchIntent>(onInvoke: (intent) => _handleToggleSearch()),
      SwitchTabIntent: CallbackAction<SwitchTabIntent>(onInvoke: (intent) => _handleSwitchTab(intent.tabIndex)),
    };

    return FocusScope(
      child: Actions(
        actions: actions,
        child: Shortcuts(
          shortcuts: shortcuts,
          child: Scaffold(
            key: _scaffoldKey,
            extendBodyBehindAppBar: false,
            backgroundColor: Theme.of(context).colorScheme.surface,
            drawer: Drawer(
              child: Column(
                children: [
                   const SizedBox(height: 32),
                   Expanded(child: const CategoryPanel()),
                   const Divider(),
                   ListTile(
                     leading: const Icon(Icons.emoji_events_outlined),
                     title: const Text('成就'),
                     onTap: () {
                       Navigator.pop(context);
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const AchievementsScreen()));
                     },
                   ),
                   ListTile(
                     leading: const Icon(Icons.settings_outlined),
                     title: const Text('设置'),
                     onTap: () {
                       Navigator.pop(context);
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                     },
                   ),
                   const SizedBox(height: 16),
                ],
              ),
            ),
            body: SafeArea(child: _pages[_currentIndex]),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Colors.grey,
              selectedFontSize: 12, 
              unselectedFontSize: 10,
              iconSize: 20,
              selectedIconTheme: const IconThemeData(size: 20),
              unselectedIconTheme: const IconThemeData(size: 20),
              items: List.generate(
                _pages.length,
                (index) => BottomNavigationBarItem(
                  icon: Icon(_icons[index]),
                  label: _titles[index],
                ),
              ),
              onTap: _handleSwitchTab,
            ),
            floatingActionButton: _currentIndex == 0
                ? FloatingActionButton(
                    onPressed: _handleNewTask,
                    tooltip: '添加任务 (N)',
                    child: const Icon(Icons.add),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final shortcuts = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.keyN): NewTaskIntent(),
      LogicalKeySet(LogicalKeyboardKey.slash): ToggleSearchIntent(),
      LogicalKeySet(LogicalKeyboardKey.digit1): SwitchTabIntent(0),
      LogicalKeySet(LogicalKeyboardKey.digit2): SwitchTabIntent(1),
      LogicalKeySet(LogicalKeyboardKey.digit3): SwitchTabIntent(2),
      LogicalKeySet(LogicalKeyboardKey.digit4): SwitchTabIntent(3),
    };

    final actions = <Type, Action<Intent>>{
      NewTaskIntent: CallbackAction<NewTaskIntent>(onInvoke: (intent) => _handleNewTask()),
      ToggleSearchIntent: CallbackAction<ToggleSearchIntent>(onInvoke: (intent) => _handleToggleSearch()),
      SwitchTabIntent: CallbackAction<SwitchTabIntent>(onInvoke: (intent) => _handleSwitchTab(intent.tabIndex)),
    };
    
    return FocusScope(
      child: Actions(
        actions: actions,
        child: Shortcuts(
          shortcuts: shortcuts,
          child: Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  CollapsibleSidebar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _handleSwitchTab,
                    destinations: List.generate(
                      _pages.length,
                      (index) => NavigationRailDestination(
                        icon: Icon(_icons[index]),
                        label: Text(_titles[index]),
                      ),
                    ),
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    child: _pages[_currentIndex],
                  ),
                ],
              ),
            ),
             floatingActionButton: _currentIndex == 0
                ? FloatingActionButton(
                    onPressed: _handleNewTask,
                    tooltip: '添加任务 (N)',
                    child: const Icon(Icons.add),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  void _showQuickAddTaskDialog(BuildContext context) {
    if (PlatformUtil.isDesktop) {
      _showDesktopQuickAddTaskDialog(context);
    } else {
      _showMobileQuickAddTaskSheet(context);
    }
  }

  void _showMobileQuickAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (modalContext, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: _QuickAddTaskForm(
                onTaskAdded: () => Navigator.pop(context),
              ),
            );
          },
        );
      },
    );
  }

  void _showDesktopQuickAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加新任务'),
          content: SizedBox(
            width: 400,
            child: _QuickAddTaskForm(
              onTaskAdded: () => Navigator.pop(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }


  void _showLevelUpDialog(int newLevel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                '升级啦！',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '恭喜你达到了等级 $newLevel!',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('太棒了！'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickAddTaskForm extends StatefulWidget {
  final VoidCallback onTaskAdded;
  const _QuickAddTaskForm({required this.onTaskAdded});

  @override
  __QuickAddTaskFormState createState() => __QuickAddTaskFormState();
}



class __QuickAddTaskFormState extends State<_QuickAddTaskForm> {
  final TextEditingController titleController = TextEditingController();
  DateTime? selectedDueDate;
  bool isImportant = false;
  bool isUrgent = false;
  int? selectedCategoryId;
  
  // Smart Input State
  ParsedTaskData? _parsedData;

  @override
  void initState() {
    super.initState();
    titleController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    titleController.removeListener(_onTextChanged);
    titleController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = titleController.text;
    if (text.isEmpty) {
      setState(() => _parsedData = null);
      return;
    }
    setState(() {
      _parsedData = SmartInputParser.parse(text);
    });
  }

  void _submitTask() {
    // If we have parsed data, use the CLEANED title, unless manual overrides exist
    // Actually, simpler logic: Input text is source of truth for title, but we might want to strip the specific tags?
    // Let's use the parsed title for the final task, and parsed attributes.
    // If user manually selected a date, that takes precedence.
    
    // Logic: Use parsed data as base, manual selections override.
    
    if (titleController.text.isNotEmpty) {
      HapticService.mediumImpact();
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      final effectiveTitle = _parsedData?.title ?? titleController.text;
      final effectiveDueDate = selectedDueDate ?? _parsedData?.dueDate;
      final effectiveIsImportant = isImportant || (_parsedData?.isImportant ?? false);
      final effectiveIsUrgent = isUrgent || (_parsedData?.isUrgent ?? false);
      
      // Category needs ID lookup if parsed by name, which is tricky without provider access in parser.
      // For now, let's ignore parsed category name unless we map it.
      // Or we can loop categories here.
      int? finalCatId = selectedCategoryId;
      if (finalCatId == null && _parsedData?.categoryName != null) {
          // Try to find category by name
          final categories = Provider.of<CategoryProvider>(context, listen: false).categories;
          for (var cat in categories) {
             if (cat.name.toLowerCase() == _parsedData!.categoryName!.toLowerCase()) {
               finalCatId = cat.id;
               break;
             }
          }
      }

      final task = Task(
        title: effectiveTitle,
        description: '',
        isCompleted: false,
        isImportant: effectiveIsImportant,
        isUrgent: effectiveIsUrgent,
        categoryId: finalCatId,
        dueDate: effectiveDueDate,
        createdAt: DateTime.now(),
        repeatFrequency: _parsedData?.repeatFrequency,
        repeatInterval: _parsedData?.repeatInterval,
        isRepeating: _parsedData?.repeatFrequency != null,
      );
      taskProvider.addTask(task);
      widget.onTaskAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: PlatformUtil.isDesktop 
          ? BorderRadius.circular(8)
          : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: '准备做什么? 试着输入 "明天下午 重要 !"',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                  ),
                  autofocus: true,
                  maxLines: 3,
                  minLines: 1,
                  style: const TextStyle(fontSize: 16),
                  onSubmitted: (_) => _submitTask(),
                ),
                // Smart Tags Preview
                if (_parsedData != null && (_parsedData!.dueDate != null || _parsedData!.isImportant || _parsedData!.isUrgent || _parsedData!.categoryName != null || _parsedData!.repeatFrequency != null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (_parsedData!.dueDate != null)
                          _buildSmartTag(Icons.calendar_today, '识别到日期', Colors.blue),
                        if (_parsedData!.isImportant)
                          _buildSmartTag(Icons.priority_high, '重要', Colors.orange),
                        if (_parsedData!.isUrgent)
                          _buildSmartTag(Icons.notification_important, '紧急', Colors.red),
                        if (_parsedData!.categoryName != null)
                          _buildSmartTag(Icons.label, _parsedData!.categoryName!, Colors.green),
                        if (_parsedData!.repeatFrequency != null)
                          _buildSmartTag(Icons.repeat, '重复: ${_parsedData!.repeatFrequency}', Colors.purple),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQuickOptionButton(
                context,
                icon: Icons.calendar_today_outlined,
                tooltip: '设置截止日期',
                isActive: selectedDueDate != null || (_parsedData?.dueDate != null),
                onPressed: () async {
                  HapticService.lightImpact();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => selectedDueDate = date);
                  }
                },
              ),
              _buildQuickOptionButton(
                context,
                icon: Icons.flag_outlined,
                tooltip: '设置优先级',
                isActive: isImportant || isUrgent || (_parsedData?.isImportant ?? false) || (_parsedData?.isUrgent ?? false),
                onPressed: () {
                  HapticService.lightImpact();
                  _showPriorityPicker();
                },
              ),
              _buildQuickOptionButton(
                context,
                icon: Icons.label_outline,
                tooltip: '选择分类',
                isActive: selectedCategoryId != null || (_parsedData?.categoryName != null),
                onPressed: () {
                   HapticService.lightImpact();
                   // ...
                   _showCategoryPicker(context, selectedCategoryId, (categoryId) {
                     setState(() => selectedCategoryId = categoryId);
                   });
                },
              ),
              // ...
              const Spacer(),
              ElevatedButton(
                onPressed: _submitTask,
                 // ...
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('添加'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
// ...

  void _showPriorityPicker() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('设置优先级'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('重要'),
              value: isImportant,
              onChanged: (value) {
                setState(() => isImportant = value ?? false);
                Navigator.pop(dialogContext);
                _showPriorityPicker();
              },
            ),
            CheckboxListTile(
              title: const Text('紧急'),
              value: isUrgent,
              onChanged: (value) {
                setState(() => isUrgent = value ?? false);
                Navigator.pop(dialogContext);
                _showPriorityPicker();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('完成'),
          )
        ],
      ),
    );
  }

  Widget _buildQuickOptionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, int? currentCategoryId, Function(int?) onCategorySelected) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          final categories = categoryProvider.categories;
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择分类',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...categories.map((category) => ListTile(
                  leading: Icon(
                    IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                    color: category.color,
                  ),
                  title: Text(category.name),
                  trailing: currentCategoryId == category.id 
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                  onTap: () {
                    onCategorySelected(category.id);
                    Navigator.pop(context);
                  },
                )).toList(),
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: const Text('无分类'),
                  trailing: currentCategoryId == null 
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                  onTap: () {
                    onCategorySelected(null);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
