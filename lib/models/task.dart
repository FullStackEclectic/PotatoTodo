import '../constants/quadrant_constants.dart';

const Object _copyWithUnset = Object();

class Task {
  final int? id;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isImportant;
  final bool isUrgent;
  final int? categoryId;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final int reminderPriority;
  final String? repeatFrequency;
  final int? repeatInterval;
  final bool isRepeating;
  final int? parentTaskId;
  final int position;
  final List<Task> subTasks;

  // 获取任务所属象限
  QuadrantType get quadrant {
    if (isImportant && isUrgent) {
      return QuadrantType.importantUrgent;
    } else if (isImportant && !isUrgent) {
      return QuadrantType.importantNotUrgent;
    } else if (!isImportant && isUrgent) {
      return QuadrantType.notImportantUrgent;
    } else {
      return QuadrantType.notImportantNotUrgent;
    }
  }

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.isImportant = false,
    this.isUrgent = false,
    this.categoryId,
    this.dueDate,
    DateTime? createdAt,
    this.updatedAt,
    this.completedAt,
    this.reminderPriority = 2,
    this.repeatFrequency,
    this.repeatInterval,
    this.isRepeating = false,
    this.parentTaskId,
    this.position = 0,
    this.subTasks = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  // 从Map创建Task对象（用于数据库读取）
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      isCompleted:
          map['isCompleted'] == 1 ||
          map['isCompleted'] == true, // Support boolean from JSON
      isImportant: map['isImportant'] == 1 || map['isImportant'] == true,
      isUrgent: map['isUrgent'] == 1 || map['isUrgent'] == true,
      categoryId: map['categoryId'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      completedAt:
          map['completedAt'] != null
              ? DateTime.parse(map['completedAt'])
              : null,
      reminderPriority: map['reminderPriority'] ?? 2,
      repeatFrequency: map['repeatFrequency'],
      repeatInterval: map['repeatInterval'],
      isRepeating: map['isRepeating'] == 1 || map['isRepeating'] == true,
      parentTaskId: map['parentTaskId'],
      position: map['position'] ?? 0,
      subTasks: [], // 子任务需要单独查询
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) => Task.fromMap(json);

  // 将Task对象转换为Map（用于数据库保存）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'isImportant': isImportant ? 1 : 0,
      'isUrgent': isUrgent ? 1 : 0,
      'categoryId': categoryId,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'reminderPriority': reminderPriority,
      'repeatFrequency': repeatFrequency,
      'repeatInterval': repeatInterval,
      'isRepeating': isRepeating ? 1 : 0,
      'parentTaskId': parentTaskId,
      'position': position,
    };
  }

  Map<String, dynamic> toJson() {
    // JSON needs booleans, Database needs 0/1 usually.
    // Let's stick to map format but ensure boolean compatibility if needed.
    // Actually, for JSON export, proper booleans are nicer.
    final map = toMap();
    map['isCompleted'] = isCompleted;
    map['isImportant'] = isImportant;
    map['isUrgent'] = isUrgent;
    map['isRepeating'] = isRepeating;
    return map;
  }

  // 创建Task的副本
  Task copyWith({
    Object? id = _copyWithUnset,
    String? title,
    String? description,
    bool? isCompleted,
    bool? isImportant,
    bool? isUrgent,
    Object? categoryId = _copyWithUnset,
    Object? dueDate = _copyWithUnset,
    DateTime? createdAt,
    Object? updatedAt = _copyWithUnset,
    Object? completedAt = _copyWithUnset,
    int? reminderPriority,
    Object? repeatFrequency = _copyWithUnset,
    Object? repeatInterval = _copyWithUnset,
    bool? isRepeating,
    Object? parentTaskId = _copyWithUnset,
    int? position,
    List<Task>? subTasks,
  }) {
    return Task(
      id: id == _copyWithUnset ? this.id : id as int?,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      isUrgent: isUrgent ?? this.isUrgent,
      categoryId:
          categoryId == _copyWithUnset ? this.categoryId : categoryId as int?,
      dueDate: dueDate == _copyWithUnset ? this.dueDate : dueDate as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt:
          updatedAt == _copyWithUnset ? this.updatedAt : updatedAt as DateTime?,
      completedAt:
          completedAt == _copyWithUnset
              ? this.completedAt
              : completedAt as DateTime?,
      reminderPriority: reminderPriority ?? this.reminderPriority,
      repeatFrequency:
          repeatFrequency == _copyWithUnset
              ? this.repeatFrequency
              : repeatFrequency as String?,
      repeatInterval:
          repeatInterval == _copyWithUnset
              ? this.repeatInterval
              : repeatInterval as int?,
      isRepeating: isRepeating ?? this.isRepeating,
      parentTaskId:
          parentTaskId == _copyWithUnset
              ? this.parentTaskId
              : parentTaskId as int?,
      position: position ?? this.position,
      subTasks: subTasks ?? this.subTasks,
    );
  }

  // 获取子任务完成率
  double get subTaskCompletionRate {
    if (subTasks.isEmpty) return 0.0;
    final completedSubTasks = subTasks.where((task) => task.isCompleted).length;
    return completedSubTasks / subTasks.length;
  }

  // 检查是否为主任务（没有父任务）
  bool get isMainTask => parentTaskId == null;

  // 检查是否为子任务
  bool get isSubTask => parentTaskId != null;
}
