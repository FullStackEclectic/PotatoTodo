import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/quadrant_constants.dart';
import '../models/quadrant_stats.dart';

class QuadrantDistributionChart extends StatelessWidget {
  final QuadrantStats stats;
  final double size;

  const QuadrantDistributionChart({
    Key? key,
    required this.stats,
    this.size = 250,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 饼图
          CustomPaint(
            size: Size(size, size),
            painter: _QuadrantPieChartPainter(stats: stats),
          ),
          
          // 中心文本
          Container(
            width: size * 0.4,
            height: size * 0.4,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${stats.totalCount}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '总任务',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
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

class _QuadrantPieChartPainter extends CustomPainter {
  final QuadrantStats stats;

  _QuadrantPieChartPainter({required this.stats});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    
    // 如果没有任务，画一个灰色圆圈
    if (stats.totalCount == 0) {
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.2;
      
      canvas.drawCircle(center, radius * 0.9, paint);
      return;
    }
    
    // 计算各象限的弧度
    double startAngle = -pi / 2; // 从12点钟方向开始
    
    // 画四个象限
    _drawQuadrantSection(
      canvas, 
      center, 
      radius, 
      startAngle, 
      stats.importantUrgentPercent,
      QuadrantType.importantUrgent,
    );
    
    startAngle += 2 * pi * stats.importantUrgentPercent / 100;
    
    _drawQuadrantSection(
      canvas, 
      center, 
      radius, 
      startAngle, 
      stats.importantNotUrgentPercent,
      QuadrantType.importantNotUrgent,
    );
    
    startAngle += 2 * pi * stats.importantNotUrgentPercent / 100;
    
    _drawQuadrantSection(
      canvas, 
      center, 
      radius, 
      startAngle, 
      stats.notImportantUrgentPercent,
      QuadrantType.notImportantUrgent,
    );
    
    startAngle += 2 * pi * stats.notImportantUrgentPercent / 100;
    
    _drawQuadrantSection(
      canvas, 
      center, 
      radius, 
      startAngle, 
      stats.notImportantNotUrgentPercent,
      QuadrantType.notImportantNotUrgent,
    );
  }
  
  void _drawQuadrantSection(
    Canvas canvas, 
    Offset center, 
    double radius, 
    double startAngle, 
    double percent, 
    QuadrantType quadrant,
  ) {
    if (percent <= 0) return;
    
    final sweepAngle = 2 * pi * percent / 100;
    final quadrantColor = QuadrantConstants.getQuadrantColor(quadrant);
    
    // 绘制扇形
    final paint = Paint()
      ..color = quadrantColor
      ..style = PaintingStyle.fill;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true,
      paint,
    );
    
    // 绘制标签线和文本
    if (percent >= 5) { // 只有占比大于5%才显示标签
      final midAngle = startAngle + sweepAngle / 2;
      
      // 计算标签位置
      final labelRadius = radius * 0.7;
      final labelX = center.dx + labelRadius * cos(midAngle);
      final labelY = center.dy + labelRadius * sin(midAngle);
      
      // 绘制标签文本背景
      final textPaint = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(labelX, labelY), radius * 0.15, textPaint);
      
      // 绘制标签文本
      final textSpan = TextSpan(
        text: '${percent.toInt()}%',
        style: TextStyle(
          color: quadrantColor,
          fontSize: radius * 0.1,
          fontWeight: FontWeight.bold,
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      textPainter.layout();
      
      textPainter.paint(
        canvas,
        Offset(
          labelX - textPainter.width / 2,
          labelY - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
} 