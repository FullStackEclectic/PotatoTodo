import 'package:flutter/material.dart';

class IconPicker extends StatelessWidget {
  final IconData selectedIcon;
  final Function(IconData) onIconSelected;
  final Color? iconColor;
  final double iconSize;
  final double spacing;

  const IconPicker({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
    this.iconColor,
    this.iconSize = 30,
    this.spacing = 15,
  });

  // 预定义常用图标列表
  static const List<IconData> icons = [
    Icons.home,
    Icons.work,
    Icons.school,
    Icons.shopping_cart,
    Icons.favorite,
    Icons.star,
    Icons.bookmark,
    Icons.lightbulb,
    Icons.local_cafe,
    Icons.restaurant,
    Icons.fitness_center,
    Icons.directions_run,
    Icons.sports_basketball,
    Icons.sports_esports,
    Icons.music_note,
    Icons.movie,
    Icons.brush,
    Icons.camera_alt,
    Icons.laptop,
    Icons.phone_android,
    Icons.directions_car,
    Icons.flight,
    Icons.schedule,
    Icons.access_time,
    Icons.euro,
    Icons.attach_money,
    Icons.account_balance,
    Icons.credit_card,
    Icons.cake,
    Icons.celebration,
    Icons.people,
    Icons.family_restroom,
    Icons.child_care,
    Icons.pets,
    Icons.medical_services,
    Icons.local_hospital,
    Icons.book,
    Icons.library_books,
    Icons.description,
    Icons.menu_book,
  ];

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Theme.of(context).primaryColor;

    return SingleChildScrollView(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children:
            icons.map((icon) {
              final isSelected = icon.codePoint == selectedIcon.codePoint;
              return GestureDetector(
                onTap: () => onIconSelected(icon),
                child: Container(
                  width: iconSize * 1.8,
                  height: iconSize * 1.8,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? color.withValues(alpha: 0.1)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isSelected
                              ? color
                              : Colors.grey.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? color : Colors.grey,
                    size: iconSize,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
