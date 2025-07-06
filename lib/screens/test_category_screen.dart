import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';

class TestCategoryScreen extends StatefulWidget {
  const TestCategoryScreen({Key? key}) : super(key: key);

  @override
  State<TestCategoryScreen> createState() => _TestCategoryScreenState();
}

class _TestCategoryScreenState extends State<TestCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';
  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = Icons.label;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    // 验证输入
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _statusMessage = '请输入分类名称';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '添加分类中...';
    });

    try {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      
      final newCategory = TaskCategory(
        name: _nameController.text.trim(),
        color: _selectedColor,
        iconCodePoint: _selectedIcon.codePoint,
      );
      
      debugPrint('[TestCategoryScreen] 创建分类: ${newCategory.name}, color=${newCategory.color.value}, icon=${newCategory.iconCodePoint}');
      await categoryProvider.addCategory(newCategory);
      
      setState(() {
        _statusMessage = '添加成功！';
        _nameController.clear();
      });
    } catch (e) {
      setState(() {
        _statusMessage = '添加失败: $e';
      });
      debugPrint('[TestCategoryScreen] 添加分类失败: $e');
      if (e is Error) {
        debugPrint('[TestCategoryScreen] 错误堆栈: ${e.stackTrace}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类测试'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '创建新分类',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '分类名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('选择颜色', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Colors.red,
                  Colors.pink,
                  Colors.purple,
                  Colors.deepPurple,
                  Colors.indigo,
                  Colors.blue,
                  Colors.lightBlue,
                  Colors.cyan,
                  Colors.teal,
                  Colors.green,
                  Colors.orange,
                  Colors.amber,
                ].map((color) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == color ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: _selectedColor == color ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
                          ] : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('选择图标', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icons.label,
                  Icons.work,
                  Icons.school,
                  Icons.shopping_cart,
                  Icons.home,
                  Icons.favorite,
                  Icons.book,
                  Icons.sports_soccer,
                  Icons.movie,
                  Icons.music_note,
                ].map((icon) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIcon = icon;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _selectedIcon == icon ? _selectedColor.withOpacity(0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: _selectedIcon == icon ? _selectedColor : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('添加分类'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: TextStyle(
                color: _statusMessage.contains('成功') ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '现有分类',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('分类列表', style: TextStyle(fontWeight: FontWeight.w500)),
                TextButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('确认操作'),
                        content: const Text('确定要清除所有分类吗？此操作不可恢复！'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed == true) {
                      setState(() {
                        _statusMessage = '正在清除所有分类...';
                        _isLoading = true;
                      });
                      
                      try {
                        await Provider.of<CategoryProvider>(context, listen: false).clearAllCategories();
                        setState(() {
                          _statusMessage = '所有分类已清除';
                        });
                      } catch (e) {
                        setState(() {
                          _statusMessage = '清除失败: $e';
                        });
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text('清除所有', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<CategoryProvider>(
                builder: (context, provider, _) {
                  final categories = provider.categories;
                  
                  if (categories.isEmpty) {
                    return const Center(
                      child: Text('没有分类'),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: category.color,
                            child: Icon(
                              IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(category.name),
                          subtitle: Text(
                            'ID: ${category.id} | 颜色: 0x${category.color.value.toRadixString(16)} | 图标: ${category.iconCodePoint}',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 