# 🍅 PotatoTodo

一个简单而强大的四象限任务管理应用，使用 Flutter 开发。

## ✨ 功能特点

### 🎯 核心功能
- **四象限任务管理**：基于艾森豪威尔矩阵的任务分类
- **跨平台支持**：Android、iOS、Web、Windows、macOS、Linux
- **智能任务推荐**：根据任务优先级和时间管理建议
- **番茄钟专注**：内置番茄工作法计时器
- **数据统计**：任务完成率、时间投入分析
- **主题切换**：支持浅色/深色主题

### 📱 已实现功能
1. **四象限管理**
   - 重要且紧急任务管理
   - 重要不紧急任务管理  
   - 紧急不重要任务管理
   - 不重要不紧急任务管理
   - 四象限视图切换
   - 任务象限分析
   - 象限任务统计

2. **任务管理**
   - 添加、编辑、删除任务
   - 标记任务完成状态
   - 设置任务优先级
   - 任务分类管理
   - 任务提醒设置

3. **番茄钟功能**
   - 自定义工作时长
   - 自定义休息时长
   - 番茄钟统计
   - 专注模式
   - 音频提醒

4. **数据管理**
   - 本地数据库存储
   - 数据导入导出
   - 离线支持
   - 数据备份恢复

5. **游戏化成长系统**
   - 任务完成与专注获得 XP 经验值与等级提升
   - 勋章成就体系（专注大师、打卡达人、早起鸟等）
   - 连续天数（Streak）精确计算

## 🛠️ 技术栈

- **Flutter** - 跨平台UI框架
- **Provider** - 状态管理
- **SQLite / IndexedDB** - 跨平台本地数据库（包含原生与 Web 支持）
- **SharedPreferences** - 本地轻量级存储
- **Flutter Local Notifications** - 本地通知与时区提醒
- **FL Chart** - 高颜值数据统计图表
- **Audioplayers** - 零延迟特效提示音与专注音效

## 🚀 快速开始

### 环境要求
- Flutter SDK: 3.44.8+ (stable)
- Dart SDK: 3.12.2+ (bundled with Flutter)
- Android Studio / VS Code

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/FullStackEclectics/PotatoTodo.git
cd PotatoTodo
```

2. **安装依赖**
```bash
flutter pub get
```

3. **运行项目**
```bash
# Web版本
flutter run -d chrome

# Android版本
flutter run -d android

# iOS版本
flutter run -d ios
```

## 📖 使用指南

### 四象限管理
1. 打开应用，默认进入四象限视图
2. 点击"+"按钮添加新任务
3. 设置任务的重要性和紧急性
4. 任务会自动分配到对应象限
5. 点击象限查看详细任务列表

### 番茄钟使用
1. 在底部导航栏选择"番茄钟"
2. 设置工作时间和休息时间
3. 点击开始专注
4. 完成番茄钟后查看统计

## 🤝 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 Apache-2.0 许可证 - 详见 [LICENSE](LICENSE) 文件

## 📞 联系方式

- **项目维护者**: FullStackEclectics
- **邮箱**: fseclectics@gmail.com
- **项目主页**: [https://github.com/FullStackEclectics/PotatoTodo](https://github.com/FullStackEclectics/PotatoTodo)

## 🙏 致谢

感谢所有为这个项目做出贡献的开发者！
