import 'package:flutter/material.dart';

class TaskCategory {
  final int? id;
  final String name;
  final Color color;
  final int iconCodePoint;

  TaskCategory({
    this.id,
    required this.name,
    required this.color,
    required this.iconCodePoint,
  });

  // 从Map创建TaskCategory对象（用于数据库读取）
  factory TaskCategory.fromMap(Map<String, dynamic> map) {
    return TaskCategory(
      id: map['id'],
      name: map['name'],
      color: Color(map['color']),
      iconCodePoint: map['iconCodePoint'] ?? Icons.label.codePoint,
    );
  }

  // 将TaskCategory对象转换为Map（用于数据库保存）
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color.value,
      'iconCodePoint': iconCodePoint,
    };
  }

  // 创建TaskCategory的副本
  TaskCategory copyWith({
    int? id,
    String? name,
    Color? color,
    int? iconCodePoint,
  }) {
    return TaskCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }
} 