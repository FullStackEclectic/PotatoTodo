import 'package:flutter/material.dart';
import '../utils/status_bar_util.dart';

class StatusBarTestScreen extends StatelessWidget {
  const StatusBarTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = StatusBarUtil.getStatusBarHeight(context);
    
    return Scaffold(
      body: Column(
        children: [
          // 状态栏区域指示器
          Container(
            height: statusBarHeight,
            width: double.infinity,
            color: Colors.red.withOpacity(0.3),
            child: Center(
              child: Text(
                '状态栏区域 (${statusBarHeight.toStringAsFixed(1)}px)',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // 内容区域
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.blue.withOpacity(0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '状态栏测试页面',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '状态栏高度: ${statusBarHeight.toStringAsFixed(1)}px',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('返回'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}