import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../widgets/color_picker.dart';
import '../widgets/icon_picker.dart';

class CategoryFormScreen extends StatefulWidget {
  final TaskCategory? category;

  const CategoryFormScreen({
    Key? key,
    this.category,
  }) : super(key: key);

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late Color _selectedColor;
  late IconData _selectedIcon;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    // 如果是编辑模式，使用现有分类的数据
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedColor = widget.category!.color;
      _selectedIcon = widget.category!.icon;
    } else {
      // 否则使用默认值
      _selectedColor = Colors.blue;
      _selectedIcon = Icons.folder;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 保存分类
  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      
      final category = TaskCategory(
        id: widget.category?.id,
        name: _nameController.text.trim(),
        color: _selectedColor,
        icon: _selectedIcon,
      );
      
      if (widget.category == null) {
        // 创建新分类
        await categoryProvider.addCategory(category);
      } else {
        // 更新现有分类
        await categoryProvider.updateCategory(category);
      }
      
      // 返回上一页
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存分类失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? '添加分类' : '编辑分类'),
        actions: [
          IconButton(
            onPressed: _isSubmitting ? null : _saveCategory,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check),
            tooltip: '保存',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 分类名称
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '分类名称',
                    hintText: '输入分类名称',
                    prefixIcon: Icon(
                      _selectedIcon,
                      color: _selectedColor,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入分类名称';
                    }
                    return null;
                  },
                  autofocus: widget.category == null,
                ),
                
                const SizedBox(height: 24),
                
                // 分类图标
                Text(
                  '选择图标',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                IconPicker(
                  selectedIcon: _selectedIcon,
                  iconColor: _selectedColor,
                  onIconSelected: (icon) {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                
                // 分类颜色
                Text(
                  '选择颜色',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ColorPicker(
                  selectedColor: _selectedColor,
                  onColorSelected: (color) {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                
                // 预览
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '预览',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: Icon(
                            _selectedIcon,
                            color: _selectedColor,
                            size: 28,
                          ),
                          title: Text(
                            _nameController.text.isEmpty ? '分类名称' : _nameController.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          tileColor: _selectedColor.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: _selectedColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 