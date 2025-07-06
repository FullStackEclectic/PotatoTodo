import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 导入键盘服务
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import 'home_screen.dart';
import 'quadrant_view_screen.dart';
import 'quadrant_stats_screen.dart';
import 'category_list_screen.dart';
import 'settings_screen.dart';
import 'task_detail_screen.dart';
import '../constants/quadrant_constants.dart'; // 导入象限常量
import 'pomodoro_screen.dart'; // 导入番茄钟屏幕

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
  final FocusNode _searchFocusNode = FocusNode(); // 添加 FocusNode 用于搜索框
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_currentIndex == 0) {
        Provider.of<TaskProvider>(context, listen: false).setSearchQuery(_searchController.text);
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose(); // Dispose FocusNode
    super.dispose();
  }
  
  // 页面列表
  final List<Widget> _pages = [
    const HomeScreen(),
    const QuadrantViewScreen(initialQuadrant: QuadrantType.importantUrgent, showAsGrid: true),
    const PomodoroScreen(),
    const SettingsScreen(),
  ];
  
  // 页面标题
  final List<String> _titles = ['任务', '四象限', '专注', '设置'];
  
  // 页面图标
  final List<IconData> _icons = [
    Icons.task,
    Icons.grid_view,
    Icons.timer,
    Icons.settings,
  ];
  
  // 切换主题
  void _toggleTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleThemeMode();
  }
  
  // 切换搜索状态
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        Provider.of<TaskProvider>(context, listen: false).setSearchQuery(null);
        _searchFocusNode.unfocus(); // 关闭搜索时取消焦点
      }
    });
    // 焦点请求移至 _handleToggleSearch
  }
  
  // 添加任务
  void _addTask() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TaskDetailScreen(),
      ),
    );
  }
  
  // 添加分类
  void _addCategory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CategoryListScreen(initiallyShowForm: true),
      ),
    );
  }

  // --- Action 处理逻辑 ---
  void _handleNewTask() {
    _addTask(); // 调用已有的添加任务方法
  }

  void _handleToggleSearch() {
    _toggleSearch(); // 调用已有的切换搜索方法
    if (_isSearching) {
      _searchFocusNode.requestFocus(); // 搜索时自动聚焦
    } else {
      _searchFocusNode.unfocus();
    }
  }

  void _handleSwitchTab(int index) {
    if (_currentIndex != index) {
      // 切换页面前清除搜索状态
      if (_isSearching) {
        _toggleSearch();
      }
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- 定义 Shortcuts 映射 (更新数字键映射)
    final shortcuts = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.keyN): NewTaskIntent(),
      LogicalKeySet(LogicalKeyboardKey.slash): ToggleSearchIntent(),
      LogicalKeySet(LogicalKeyboardKey.digit1): SwitchTabIntent(0), // 任务
      LogicalKeySet(LogicalKeyboardKey.digit2): SwitchTabIntent(1), // 四象限
      LogicalKeySet(LogicalKeyboardKey.digit3): SwitchTabIntent(2), // 专注
      LogicalKeySet(LogicalKeyboardKey.digit4): SwitchTabIntent(3), // 设置
      // LogicalKeySet(LogicalKeyboardKey.digit5): SwitchTabIntent(4),
    };

    // --- 定义 Actions 映射 ---
    final actions = <Type, Action<Intent>>{
      NewTaskIntent: CallbackAction<NewTaskIntent>(
        onInvoke: (intent) => _handleNewTask(),
      ),
      ToggleSearchIntent: CallbackAction<ToggleSearchIntent>(
        onInvoke: (intent) => _handleToggleSearch(),
      ),
      SwitchTabIntent: CallbackAction<SwitchTabIntent>(
        onInvoke: (intent) => _handleSwitchTab(intent.tabIndex),
      ),
    };

    // 使用 FocusScope 管理焦点
    return FocusScope(
      child: Actions(
        actions: actions,
        child: Shortcuts(
          shortcuts: shortcuts,
          child: Scaffold(
            appBar: _currentIndex != 3
                ? AppBar(
                    title: _isSearching && _currentIndex == 0
                        ? TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode, // 关联 FocusNode
                            autofocus: true, // 初始可以 autofocus，但后续由 _handleToggleSearch 控制
                            decoration: const InputDecoration(
                              hintText: '搜索任务 (按 / 退出)...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.white70),
                            ),
                            style: const TextStyle(color: Colors.white),
                          )
                        : Text(_titles[_currentIndex]),
                    actions: [
                      if (_currentIndex == 1)
                        IconButton(
                          icon: const Icon(Icons.analytics),
                          tooltip: '四象限分析',
                          onPressed: () {
                            Navigator.pushNamed(context, '/quadrant-stats');
                          },
                        ),
                      if (_currentIndex == 0 && !_isSearching)
                        IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: '搜索 (/)',
                          onPressed: _handleToggleSearch,
                        ),
                      if (_isSearching)
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: '关闭搜索 (/)',
                          onPressed: _handleToggleSearch,
                        ),
                      IconButton(
                        icon: const Icon(Icons.brightness_6),
                        onPressed: _toggleTheme,
                      ),
                    ],
                    toolbarHeight: 46, // 减小顶部菜单高度
                    iconTheme: const IconThemeData(size: 20), // 减小图标大小
                    titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16), // 减小标题字体大小
                  )
                : null,
            drawer: _currentIndex == 0
                ? Drawer(
                    child: Consumer<CategoryProvider>(
                      builder: (context, categoryProvider, _) {
                        final categories = categoryProvider.categories;
                        final taskProvider = Provider.of<TaskProvider>(context);
                        
                        return Column(
                          children: [
                            // 抽屉顶部
                            DrawerHeader(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '土豆 Todo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '高效的任务四象限管理工具',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // 显示已完成任务开关
                            SwitchListTile(
                              secondary: const Icon(Icons.check_circle),
                              title: const Text('显示已完成任务'),
                              value: taskProvider.showCompletedTasks,
                              onChanged: (value) {
                                taskProvider.setShowCompletedTasks(value);
                              },
                            ),
                            
                            const Divider(),
                            
                            // 分类标题
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '任务分类',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('新建分类'),
                                    onPressed: () {
                                      Navigator.pop(context); // 关闭抽屉
                                      Navigator.pushNamed(context, '/category_list', arguments: true);
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // 分类列表
                            Expanded(
                              child: categories.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        '暂无分类\n点击"新建分类"按钮添加',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: categories.length,
                                    itemBuilder: (context, index) {
                                      final category = categories[index];
                                      return ListTile(
                                        leading: Icon(
                                          IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                                          color: category.color,
                                        ),
                                        title: Text(category.name),
                                        selected: taskProvider.selectedCategoryId == category.id,
                                        trailing: Text(
                                          taskProvider.getTasksByCategory(category.id!).length.toString(),
                                          style: TextStyle(
                                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                          ),
                                        ),
                                        onTap: () {
                                          taskProvider.setSelectedCategory(category.id);
                                          Navigator.pop(context); // 关闭抽屉
                                        },
                                      );
                                    },
                                  ),
                            ),
                            
                            const Divider(),
                            
                            // 底部按钮区域
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.settings),
                                    tooltip: '设置',
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _handleSwitchTab(3); // 切换到设置页面
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.category),
                                    tooltip: '管理分类',
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(context, '/category_list');
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.bug_report),
                                    tooltip: '测试分类',
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(context, '/test-category');
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    tooltip: '关于',
                                    onPressed: () {
                                      Navigator.pop(context);
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
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                : null,
            body: _pages[_currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Colors.grey,
              selectedFontSize: 12, // 减小选中状态的字体大小
              unselectedFontSize: 10, // 减小未选中状态的字体大小
              iconSize: 20, // 减小图标大小
              selectedIconTheme: const IconThemeData(size: 20), // 设置选中图标大小
              unselectedIconTheme: const IconThemeData(size: 20), // 设置未选中图标大小
              items: List.generate(
                _pages.length,
                (index) => BottomNavigationBarItem(
                  icon: Icon(_icons[index]),
                  label: _titles[index],
                ),
              ),
              onTap: (index) {
                _handleSwitchTab(index);
              },
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
} 