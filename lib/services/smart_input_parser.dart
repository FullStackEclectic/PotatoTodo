import 'package:flutter/material.dart';
import '../models/quadrant_type.dart';

class ParsedTaskData {
  final String title;
  final DateTime? dueDate;
  final bool isImportant;
  final bool isUrgent;
  final String? categoryName;
  final String? repeatFrequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final int? repeatInterval;

  ParsedTaskData({
    required this.title,
    this.dueDate,
    this.isImportant = false,
    this.isUrgent = false,
    this.categoryName,
    this.repeatFrequency,
    this.repeatInterval,
  });
}

class SmartInputParser {
  static ParsedTaskData parse(String input) {
    String title = input;
    DateTime? dueDate;
    bool isImportant = false;
    bool isUrgent = false;
    String? categoryName;
    String? repeatFrequency;
    int? repeatInterval;

    // 1. Parse Priority '!...'
    if (title.contains('!!!')) {
      isImportant = true;
      isUrgent = true;
      title = title.replaceAll('!!!', '');
    } else if (title.contains('!!')) {
      isUrgent = true;
      title = title.replaceAll('!!', '');
    } else if (title.contains('!')) {
      isImportant = true;
      title = title.replaceAll('!', '');
    }

    // 2. Parse Category '#...'
    final categoryRegex = RegExp(r'#(\S+)'); // \S match non-whitespace
    final categoryMatch = categoryRegex.firstMatch(title);
    if (categoryMatch != null) {
      categoryName = categoryMatch.group(1);
      title = title.replaceAll(categoryMatch.group(0)!, '');
    }

    // 3. Parse Recurrence (Before dates to avoid conflict with 'day')
    // Support: every day, daily, every week, weekly, 每天, 每周...
    final lowerTitleRef = title.toLowerCase();
    
    if (RegExp(r'(every day|daily|每天)').hasMatch(lowerTitleRef)) {
      repeatFrequency = 'daily';
      repeatInterval = 1;
      title = _removePattern(title, RegExp(r'(every\s*day|daily|每天)', caseSensitive: false));
    } else if (RegExp(r'(every week|weekly|每周)').hasMatch(lowerTitleRef)) {
      repeatFrequency = 'weekly';
      repeatInterval = 1;
      title = _removePattern(title, RegExp(r'(every\s*week|weekly|每周)', caseSensitive: false));
    } else if (RegExp(r'(every month|monthly|每月)').hasMatch(lowerTitleRef)) {
      repeatFrequency = 'monthly';
      repeatInterval = 1;
      title = _removePattern(title, RegExp(r'(every\s*month|monthly|每月)', caseSensitive: false));
    }

    // 4. Parse Dates
    final now = DateTime.now();
    final lowerTitle = title.toLowerCase();

    // 4a. Relative Keywords
    if (lowerTitle.contains('tomorrow') || lowerTitle.contains('tmr') || lowerTitle.contains('明天')) {
      dueDate = now.add(const Duration(days: 1));
      title = _removePattern(title, RegExp(r'(tomorrow|tmr|明天)', caseSensitive: false));
    } else if (lowerTitle.contains('today') || lowerTitle.contains('今天')) {
      dueDate = now;
      title = _removePattern(title, RegExp(r'(today|今天)', caseSensitive: false));
    } else if (lowerTitle.contains('next week') || lowerTitle.contains('下周')) {
      dueDate = now.add(const Duration(days: 7));
      title = _removePattern(title, RegExp(r'(next\s*week|下周)', caseSensitive: false));
    } 
    // 4b. "In X days" / "X天后"
    else {
      final inDaysRegex = RegExp(r'(in|after)\s+(\d+)\s+(days?|d)|(\d+)(天后)');
      final match = inDaysRegex.firstMatch(lowerTitle); // Check lowercase for match
      if (match != null) {
        // match.group(2) is English digit, group(4) is Chinese digit
        final daysStr = match.group(2) ?? match.group(4);
        if (daysStr != null) {
          final days = int.tryParse(daysStr);
          if (days != null) {
            dueDate = now.add(Duration(days: days));
            // Remove from original title using the matched string
            // match.group(0) is the full match string from lowerTitle. 
            // We need to find it in original title roughly? 
            // Better to just replace regex match.
            title = _removePattern(title, inDaysRegex); 
          }
        }
      }
      // 4c. Specific Date "12/25" or "12月25日"
      else {
        // MM/DD format
        final dateRegex = RegExp(r'(\d{1,2})[/-](\d{1,2})|(\d{1,2})月(\d{1,2})日?');
        final dateMatch = dateRegex.firstMatch(title);
        if (dateMatch != null) {
           int? month, day;
           if (dateMatch.group(1) != null) {
             // 12/25
             month = int.tryParse(dateMatch.group(1)!);
             day = int.tryParse(dateMatch.group(2)!);
           } else {
             // 12月25日
             month = int.tryParse(dateMatch.group(3)!);
             day = int.tryParse(dateMatch.group(4)!);
           }
           
           if (month != null && day != null) {
             // Assume current year, or next year if date passed? 
             // Simple: current year.
             dueDate = DateTime(now.year, month, day);
             if (dueDate.isBefore(now.subtract(const Duration(days: 1)))) {
               // If parsed date is properly before today (e.g. it's Dec and we type Jan 1), maybe next year?
               // But usually "12/25" means upcoming or past setting. 
               // Let's stick to current year for simplicity unless user specifies year.
               // Or smart logic: if month < now.month, next year?
               if (month < now.month) {
                 dueDate = DateTime(now.year + 1, month, day);
               }
             }
             title = _removePattern(title, dateRegex);
           }
        }
      }
    }

    // Cleanup whitespace and punctuation left over
    // Remove trailing/leading punctuation potentially
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return ParsedTaskData(
      title: title,
      dueDate: dueDate,
      isImportant: isImportant,
      isUrgent: isUrgent,
      categoryName: categoryName,
      repeatFrequency: repeatFrequency,
      repeatInterval: repeatInterval,
    );
  }

  static String _removePattern(String text, RegExp pattern) {
    return text.replaceAll(pattern, '');
  }
}
