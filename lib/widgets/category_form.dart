import 'package:flutter/material.dart';
import '../models/category.dart';
import 'package:provider/provider.dart';

class CategoryForm extends StatefulWidget {
  final TaskCategory? category;
  final Function(TaskCategory) onSave;

  const CategoryForm({
    Key? key,
    this.category,
    required this.onSave,
  }) : super(key: key);

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  Color _selectedColor = Colors.blue;
  int _selectedIconCodePoint = Icons.label.codePoint;
  
  // 预定义颜色列表
  final List<Color> _colors = [
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
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];
  
  // 可选图标列表
  final List<IconData> _availableIcons = [
    Icons.label,
    Icons.work,
    Icons.person,
    Icons.school,
    Icons.shopping_cart,
    Icons.favorite,
    Icons.home,
    Icons.fitness_center,
    Icons.movie,
    Icons.music_note,
    Icons.flag,
    Icons.attach_money,
    Icons.lightbulb,
    Icons.pets,
    Icons.build,
    Icons.code,
    Icons.book,
    Icons.phone,
    Icons.mail,
    Icons.star,
  ];
  
  @override
  void initState() {
    super.initState();
    
    // 初始化表单控制器
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    
    // 设置初始颜色和图标
    if (widget.category != null) {
      _selectedColor = widget.category!.color;
      _selectedIconCodePoint = widget.category!.iconCodePoint;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  void _submitForm() {
    debugPrint('[CategoryForm] 提交表单');
    if (_formKey.currentState!.validate()) {
      debugPrint('[CategoryForm] 表单验证通过，创建新分类');
      try {
        final newCategory = TaskCategory(
          id: widget.category?.id,
          name: _nameController.text.trim(),
          color: _selectedColor,
          iconCodePoint: _selectedIconCodePoint,
        );
        
        debugPrint('[CategoryForm] 新分类数据: name=${newCategory.name}, color=${newCategory.color.value}, iconCodePoint=${newCategory.iconCodePoint}');
        widget.onSave(newCategory);
      } catch (e) {
        debugPrint('[CategoryForm] 创建分类错误: $e');
        // 可以在这里显示错误信息
      }
    } else {
      debugPrint('[CategoryForm] 表单验证失败');
    }
  }
  
  // 显示颜色选择器
  void _showColorPicker() {
    // ... (颜色选择器逻辑不变)
  }
  
  // 显示图标选择器
  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择图标'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _availableIcons.length,
            itemBuilder: (context, index) {
              final iconData = _availableIcons[index];
              return IconButton(
                icon: Icon(iconData),
                color: iconData.codePoint == _selectedIconCodePoint ? Theme.of(context).primaryColor : null,
                onPressed: () {
                  setState(() {
                    _selectedIconCodePoint = iconData.codePoint;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类名称
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '分类名称',
              hintText: '输入分类名称',
              prefixIcon: Icon(Icons.category),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入分类名称';
              }
              return null;
            },
            autofocus: widget.category == null,
          ),
          
          const SizedBox(height: 24),
          
          // 颜色选择
          const Text(
            '选择颜色',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(height: 8),
          
          // 颜色网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _colors.length,
            itemBuilder: (context, index) {
              final color = _colors[index];
              final isSelected = _selectedColor.value == color.value;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: CircleAvatar(
                  backgroundColor: color,
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // 图标选择
          const Text(
            '选择图标',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(height: 8),
          
          // 图标网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _availableIcons.length,
            itemBuilder: (context, index) {
              final iconData = _availableIcons[index];
              final isSelected = iconData.codePoint == _selectedIconCodePoint;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIconCodePoint = iconData.codePoint;
                  });
                },
                child: CircleAvatar(
                  backgroundColor: isSelected ? _selectedColor : Colors.grey.shade200,
                  child: Icon(
                    iconData,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // 预览
          const Text(
            '预览',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(height: 8),
          
          // 分类预览
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _selectedColor, width: 1),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _selectedColor,
                  child: Icon(
                    IconData(_selectedIconCodePoint, fontFamily: 'MaterialIcons'),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _nameController.text.isEmpty ? '分类名称' : _nameController.text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _selectedColor,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 保存按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  widget.category == null ? '添加分类' : '保存更改',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 