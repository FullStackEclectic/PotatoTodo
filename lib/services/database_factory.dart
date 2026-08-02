import 'package:flutter/foundation.dart';
import 'database_interface.dart';
import 'sqlite_database_service.dart';
import 'web_database_service.dart';
import '../utils/platform_util.dart';

/// 数据库服务工厂类，用于根据平台选择合适的数据库实现
class DatabaseFactory {
  static DatabaseInterface getDatabaseService() {
    if (PlatformUtil.isWeb) {
      debugPrint('[DatabaseFactory] 检测到Web平台，使用WebDatabaseService');
      return WebDatabaseService();
    } else {
      debugPrint('[DatabaseFactory] 检测到非Web平台，使用SQLiteDatabaseService');
      return SQLiteDatabaseService();
    }
  }
}
