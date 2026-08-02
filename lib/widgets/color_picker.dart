import 'package:flutter/material.dart';

class ColorPicker extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;
  final double itemSize;
  final double spacing;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.itemSize = 40,
    this.spacing = 10,
  });

  // 预定义的颜色列表
  static const List<Color> colors = [
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

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children:
          colors.map((color) {
            final isSelected = color == selectedColor;
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: Container(
                width: itemSize,
                height: itemSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
              ),
            );
          }).toList(),
    );
  }
}
