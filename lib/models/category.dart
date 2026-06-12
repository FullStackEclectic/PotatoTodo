import 'package:flutter/material.dart';

class TaskCategory {
  final int? id;
  final String name;
  final Color color;
  final int iconCodePoint;
  final int? parentId; // 父分类ID，null表示顶级分类
  final int level; // 分类层级，0表示顶级分类，1表示二级分类
  final int sortOrder; // 排序顺序

  TaskCategory({
    this.id,
    required this.name,
    required this.color,
    required this.iconCodePoint,
    this.parentId,
    this.level = 0,
    this.sortOrder = 0,
  });

  // 从Map创建TaskCategory对象（用于数据库读取）
  factory TaskCategory.fromMap(Map<String, dynamic> map) {
    return TaskCategory(
      id: map['id'],
      name: map['name'],
      color: Color(map['color']),
      iconCodePoint: map['iconCodePoint'] ?? Icons.label.codePoint,
      parentId: map['parentId'],
      level: map['level'] ?? 0,
      sortOrder: map['sortOrder'] ?? 0,
    );
  }

  // 将TaskCategory对象转换为Map（用于数据库保存）
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color.toARGB32(),
      'iconCodePoint': iconCodePoint,
      'parentId': parentId,
      'level': level,
      'sortOrder': sortOrder,
    };
  }

  Map<String, dynamic> toJson() => toMap();
  factory TaskCategory.fromJson(Map<String, dynamic> json) => TaskCategory.fromMap(json);

  // 创建TaskCategory的副本
  TaskCategory copyWith({
    int? id,
    String? name,
    Color? color,
    int? iconCodePoint,
    int? parentId,
    int? level,
    int? sortOrder,
  }) {
    return TaskCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
} 