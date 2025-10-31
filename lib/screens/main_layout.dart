import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 导入键盘服务
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../models/task.dart';
import '../models/quadrant_type.dart';
import 'home_screen.dart';
import 'quadrant_view_screen.dart';
import 'quadrant_stats_screen.dart';
import 'category_list_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'calendar_screen.dart';
import 'task_detail_screen.dart';
import '../constants/quadrant_constants.dart'; // 导入象限常量
import 'pomodoro_screen.dart'; // 导入番茄钟屏幕
import '../services/haptic_service.dart'; // 导入触觉服务

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
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
  List<Widget> get _pages => [
    HomeScreen(scaffoldKey: _scaffoldKey),
    const QuadrantViewScreen(initialQuadrant: QuadrantType.importantUrgent, showAsGrid: true),
    const PomodoroScreen(),
    const CalendarScreen(),
    const StatisticsScreen(),
  ];
  
  // 页面标题
  final List<String> _titles = ['任务', '四象限', '专注', '日历', '统计'];
  
  // 页面图标
  final List<IconData> _icons = [
    Icons.task,
    Icons.grid_view,
    Icons.timer,
    Icons.calendar_today,
    Icons.analytics,
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
    _showQuickAddTaskDialog(context);
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
            key: _scaffoldKey,
            extendBodyBehindAppBar: false,
            backgroundColor: Theme.of(context).colorScheme.surface,
                         drawer: Drawer(
               child: Consumer<CategoryProvider>(
                 builder: (context, categoryProvider, _) {
                   final categories = categoryProvider.categories;
                   final taskProvider = Provider.of<TaskProvider>(context);
                   final theme = Theme.of(context);
                   
                   return Container(
                     color: theme.colorScheme.surface,
                     child: Column(
                       children: [
                         // 现代感头部区域
                         Container(
                           padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 24),
                           decoration: BoxDecoration(
                             gradient: LinearGradient(
                               begin: Alignment.topLeft,
                               end: Alignment.bottomRight,
                               colors: [
                                 theme.colorScheme.primary,
                                 theme.colorScheme.primary.withOpacity(0.8),
                               ],
                             ),
                             boxShadow: [
                               BoxShadow(
                                 color: theme.colorScheme.primary.withOpacity(0.3),
                                 blurRadius: 20,
                                 offset: const Offset(0, 4),
                               ),
                             ],
                           ),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               // 关闭按钮
                               Align(
                                 alignment: Alignment.topRight,
                                 child: IconButton(
                                   onPressed: () => Navigator.pop(context),
                                   icon: Icon(
                                     Icons.close,
                                     color: Colors.white.withOpacity(0.8),
                                     size: 20,
                                   ),
                                   style: IconButton.styleFrom(
                                     backgroundColor: Colors.white.withOpacity(0.2),
                                     shape: RoundedRectangleBorder(
                                       borderRadius: BorderRadius.circular(8),
                                     ),
                                   ),
                                 ),
                               ),
                               const SizedBox(height: 16),
                               // 应用信息
                               Row(
                                 children: [
                                   Container(
                                     padding: const EdgeInsets.all(12),
                                     decoration: BoxDecoration(
                                       color: Colors.white.withOpacity(0.2),
                                       borderRadius: BorderRadius.circular(12),
                                     ),
                                     child: const Icon(
                                       Icons.check_circle_outline,
                                       color: Colors.white,
                                       size: 24,
                                     ),
                                   ),
                                   const SizedBox(width: 16),
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         const Text(
                                           '土豆 Todo',
                                           style: TextStyle(
                                             color: Colors.white,
                                             fontSize: 20,
                                             fontWeight: FontWeight.bold,
                                           ),
                                         ),
                                         const SizedBox(height: 4),
                                         Text(
                                           '高效的任务管理工具',
                                           style: TextStyle(
                                             color: Colors.white.withOpacity(0.8),
                                             fontSize: 12,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                 ],
                               ),
                             ],
                           ),
                         ),
                         
                         // 主要内容区域
                         Expanded(
                           child: SingleChildScrollView(
                             padding: const EdgeInsets.all(20),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 // 超紧凑分类管理区域
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 标题和新建按钮
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '分类',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.onSurface.withOpacity(0.8),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.pushNamed(context, '/category_list', arguments: true);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.add,
                                                      size: 14,
                                                      color: theme.colorScheme.primary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '新建',
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color: theme.colorScheme.primary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 8),
                                        
                                                                                 // 超紧凑分类列表（支持二级分类）
                                         if (categories.isEmpty)
                                           Container(
                                             padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                             decoration: BoxDecoration(
                                               color: theme.colorScheme.surface,
                                               borderRadius: BorderRadius.circular(8),
                                               border: Border.all(
                                                 color: theme.colorScheme.outline.withOpacity(0.1),
                                               ),
                                             ),
                                             child: Row(
                                               children: [
                                                 Icon(
                                                   Icons.category_outlined,
                                                   size: 16,
                                                   color: theme.colorScheme.onSurface.withOpacity(0.4),
                                                 ),
                                                 const SizedBox(width: 8),
                                                 Text(
                                                   '暂无分类',
                                                   style: theme.textTheme.bodySmall?.copyWith(
                                                     color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                           )
                                         else
                                           Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                               // 顶级分类
                                               ...categoryProvider.topLevelCategories.map((category) {
                                                 final taskCount = taskProvider.getTasksByCategory(category.id!).length;
                                                 final isSelected = taskProvider.selectedCategoryId == category.id;
                                                 final subCategories = categoryProvider.getSubCategories(category.id!);
                                                 
                                                 return Column(
                                                   crossAxisAlignment: CrossAxisAlignment.start,
                                                   children: [
                                                     // 顶级分类标签
                                                     GestureDetector(
                                                       onTap: () {
                                                         taskProvider.setSelectedCategory(category.id);
                                                         Navigator.pop(context);
                                                       },
                                                       child: Container(
                                                         margin: const EdgeInsets.only(bottom: 4),
                                                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                         decoration: BoxDecoration(
                                                           color: isSelected 
                                                             ? theme.colorScheme.primary.withOpacity(0.15)
                                                             : theme.colorScheme.surface,
                                                           borderRadius: BorderRadius.circular(16),
                                                           border: Border.all(
                                                             color: isSelected
                                                               ? theme.colorScheme.primary.withOpacity(0.3)
                                                               : theme.colorScheme.outline.withOpacity(0.2),
                                                             width: 1,
                                                           ),
                                                         ),
                                                         child: Row(
                                                           mainAxisSize: MainAxisSize.min,
                                                           children: [
                                                             Icon(
                                                               IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                                                               color: category.color,
                                                               size: 14,
                                                             ),
                                                             const SizedBox(width: 6),
                                                             Text(
                                                               category.name,
                                                               style: theme.textTheme.bodySmall?.copyWith(
                                                                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                                 color: isSelected 
                                                                   ? theme.colorScheme.primary 
                                                                   : theme.colorScheme.onSurface.withOpacity(0.8),
                                                               ),
                                                             ),
                                                             if (taskCount > 0) ...[
                                                               const SizedBox(width: 4),
                                                               Container(
                                                                 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                                 decoration: BoxDecoration(
                                                                   color: isSelected
                                                                     ? theme.colorScheme.primary.withOpacity(0.2)
                                                                     : theme.colorScheme.outline.withOpacity(0.1),
                                                                   borderRadius: BorderRadius.circular(8),
                                                                 ),
                                                                 child: Text(
                                                                   taskCount.toString(),
                                                                   style: theme.textTheme.bodySmall?.copyWith(
                                                                     fontSize: 10,
                                                                     fontWeight: FontWeight.w600,
                                                                     color: isSelected
                                                                       ? theme.colorScheme.primary
                                                                       : theme.colorScheme.onSurface.withOpacity(0.6),
                                                                   ),
                                                                 ),
                                                               ),
                                                             ],
                                                           ],
                                                         ),
                                                       ),
                                                     ),
                                                     
                                                     // 子分类
                                                     if (subCategories.isNotEmpty)
                                                       Padding(
                                                         padding: const EdgeInsets.only(left: 16, top: 2, bottom: 4),
                                                         child: Wrap(
                                                           spacing: 4,
                                                           runSpacing: 4,
                                                           children: subCategories.map((subCategory) {
                                                             final subTaskCount = taskProvider.getTasksByCategory(subCategory.id!).length;
                                                             final isSubSelected = taskProvider.selectedCategoryId == subCategory.id;
                                                             
                                                             return GestureDetector(
                                                               onTap: () {
                                                                 taskProvider.setSelectedCategory(subCategory.id);
                                                                 Navigator.pop(context);
                                                               },
                                                               child: Container(
                                                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                 decoration: BoxDecoration(
                                                                   color: isSubSelected 
                                                                     ? theme.colorScheme.primary.withOpacity(0.1)
                                                                     : theme.colorScheme.surface,
                                                                   borderRadius: BorderRadius.circular(12),
                                                                   border: Border.all(
                                                                     color: isSubSelected
                                                                       ? theme.colorScheme.primary.withOpacity(0.2)
                                                                       : theme.colorScheme.outline.withOpacity(0.1),
                                                                     width: 0.5,
                                                                   ),
                                                                 ),
                                                                 child: Row(
                                                                   mainAxisSize: MainAxisSize.min,
                                                                   children: [
                                                                     Icon(
                                                                       IconData(subCategory.iconCodePoint, fontFamily: 'MaterialIcons'),
                                                                       color: subCategory.color,
                                                                       size: 12,
                                                                     ),
                                                                     const SizedBox(width: 4),
                                                                     Text(
                                                                       subCategory.name,
                                                                       style: theme.textTheme.bodySmall?.copyWith(
                                                                         fontSize: 11,
                                                                         fontWeight: isSubSelected ? FontWeight.w600 : FontWeight.normal,
                                                                         color: isSubSelected 
                                                                           ? theme.colorScheme.primary 
                                                                           : theme.colorScheme.onSurface.withOpacity(0.7),
                                                                       ),
                                                                     ),
                                                                     if (subTaskCount > 0) ...[
                                                                       const SizedBox(width: 3),
                                                                       Container(
                                                                         padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                                                         decoration: BoxDecoration(
                                                                           color: isSubSelected
                                                                             ? theme.colorScheme.primary.withOpacity(0.15)
                                                                             : theme.colorScheme.outline.withOpacity(0.05),
                                                                           borderRadius: BorderRadius.circular(6),
                                                                         ),
                                                                         child: Text(
                                                                           subTaskCount.toString(),
                                                                           style: theme.textTheme.bodySmall?.copyWith(
                                                                             fontSize: 9,
                                                                             fontWeight: FontWeight.w600,
                                                                             color: isSubSelected
                                                                               ? theme.colorScheme.primary
                                                                               : theme.colorScheme.onSurface.withOpacity(0.5),
                                                                           ),
                                                                         ),
                                                                       ),
                                                                     ],
                                                                   ],
                                                                 ),
                                                               ),
                                                             );
                                                           }).toList(),
                                                         ),
                                                       ),
                                                   ],
                                                 );
                                               }).toList(),
                                             ],
                                           ),
                                      ],
                                    ),
                                  ),
                               ],
                             ),
                           ),
                         ),
                         
                         // 底部操作区域
                         Container(
                           padding: const EdgeInsets.all(20),
                           decoration: BoxDecoration(
                             color: theme.colorScheme.surface,
                             border: Border(
                               top: BorderSide(
                                 color: theme.colorScheme.outline.withOpacity(0.1),
                               ),
                             ),
                           ),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                             children: [
                               _buildBottomActionButton(
                                 context,
                                 icon: Icons.settings_outlined,
                                 label: '设置',
                                 onPressed: () {
                                   Navigator.pop(context);
                                   Navigator.push(
                                     context,
                                     MaterialPageRoute(
                                       builder: (context) => const SettingsScreen(),
                                     ),
                                   );
                                 },
                               ),
                               _buildBottomActionButton(
                                 context,
                                 icon: Icons.category_outlined,
                                 label: '管理',
                                 onPressed: () {
                                   Navigator.pop(context);
                                   Navigator.pushNamed(context, '/category_list');
                                 },
                               ),
                               _buildBottomActionButton(
                                 context,
                                 icon: Icons.info_outline,
                                 label: '关于',
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
                     ),
                   );
                 },
               ),
             ),
            body: SafeArea(
              child: _pages[_currentIndex],
            ),
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

  void _showQuickAddTaskDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    DateTime? selectedDueDate;
    bool isImportant = false;
    bool isUrgent = false;
    int? selectedCategoryId;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
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
                // 大输入框 - 参考图片设计
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: '准备做什么?',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    autofocus: true,
                    maxLines: 3,
                    minLines: 1,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 快速选项图标行 - 参考图片设计
                Row(
                  children: [
                    // 日历图标
                    _buildQuickOptionButton(
                      context,
                      icon: Icons.calendar_today_outlined,
                      tooltip: '设置截止日期',
                      isActive: selectedDueDate != null,
                      onPressed: () async {
                        HapticService.lightImpact();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDueDate = date;
                          });
                        }
                      },
                    ),
                    
                    // 优先级图标
                    _buildQuickOptionButton(
                      context,
                      icon: Icons.flag_outlined,
                      tooltip: '设置优先级',
                      isActive: isImportant || isUrgent,
                      onPressed: () {
                        HapticService.lightImpact();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('设置优先级'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CheckboxListTile(
                                  title: const Text('重要'),
                                  value: isImportant,
                                  onChanged: (value) {
                                    setState(() {
                                      isImportant = value ?? false;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                                CheckboxListTile(
                                  title: const Text('紧急'),
                                  value: isUrgent,
                                  onChanged: (value) {
                                    setState(() {
                                      isUrgent = value ?? false;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // 分类图标
                    _buildQuickOptionButton(
                      context,
                      icon: Icons.label_outline,
                      tooltip: '选择分类',
                      isActive: selectedCategoryId != null,
                      onPressed: () {
                        HapticService.lightImpact();
                        _showCategoryPicker(context, selectedCategoryId, (categoryId) {
                          setState(() {
                            selectedCategoryId = categoryId;
                          });
                        });
                      },
                    ),
                    
                    // 更多选项图标
                    _buildQuickOptionButton(
                      context,
                      icon: Icons.more_horiz,
                      tooltip: '更多选项',
                      isActive: false,
                      onPressed: () {
                        HapticService.lightImpact();
                        _showMoreOptions(context, setState);
                      },
                    ),
                    
                    const Spacer(),
                    
                    // 添加按钮 - 参考图片设计
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty) {
                          HapticService.mediumImpact();
                          final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                          final task = Task(
                            title: titleController.text,
                            description: '',
                            isCompleted: false,
                            isImportant: isImportant,
                            isUrgent: isUrgent,
                            categoryId: selectedCategoryId,
                            dueDate: selectedDueDate,
                            createdAt: DateTime.now(),
                          );
                          taskProvider.addTask(task);
                          Navigator.pop(context);
                        }
                      },
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
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
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

  void _showCategoryPicker(BuildContext context, int? selectedCategoryId, Function(int?) onCategorySelected) {
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
                  trailing: selectedCategoryId == category.id 
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
                  trailing: selectedCategoryId == null 
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

     Widget _buildBottomActionButton(
     BuildContext context, {
     required IconData icon,
     required String label,
     required VoidCallback onPressed,
   }) {
     final theme = Theme.of(context);
     
     return Expanded(
       child: InkWell(
         onTap: onPressed,
         borderRadius: BorderRadius.circular(12),
         child: Container(
           padding: const EdgeInsets.symmetric(vertical: 12),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Icon(
                 icon,
                 size: 20,
                 color: theme.colorScheme.onSurface.withOpacity(0.7),
               ),
               const SizedBox(height: 4),
               Text(
                 label,
                 style: theme.textTheme.bodySmall?.copyWith(
                   color: theme.colorScheme.onSurface.withOpacity(0.7),
                   fontWeight: FontWeight.w500,
                 ),
               ),
             ],
           ),
         ),
       ),
     );
   }

   void _showMoreOptions(BuildContext context, StateSetter setState) {
     showModalBottomSheet(
       context: context,
       builder: (context) => Container(
         padding: const EdgeInsets.all(20),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(
               '更多选项',
               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                 fontWeight: FontWeight.bold,
               ),
             ),
             const SizedBox(height: 16),
             ListTile(
               leading: const Icon(Icons.description),
               title: const Text('添加描述'),
               onTap: () {
                 // TODO: 实现添加描述功能
                 Navigator.pop(context);
               },
             ),
             ListTile(
               leading: const Icon(Icons.repeat),
               title: const Text('重复任务'),
               onTap: () {
                 // TODO: 实现重复任务功能
                 Navigator.pop(context);
               },
             ),
             ListTile(
               leading: const Icon(Icons.notifications),
               title: const Text('设置提醒'),
               onTap: () {
                 // TODO: 实现提醒功能
                 Navigator.pop(context);
               },
             ),
           ],
         ),
       ),
     );
   }
} 