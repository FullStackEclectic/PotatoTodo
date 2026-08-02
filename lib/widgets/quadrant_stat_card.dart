import 'package:flutter/material.dart';
import '../constants/quadrant_constants.dart';

class QuadrantStatCard extends StatelessWidget {
  final QuadrantType quadrantType;
  final int count;
  final int totalCount;
  final VoidCallback onTap;

  const QuadrantStatCard({
    super.key,
    required this.quadrantType,
    required this.count,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final quadrantColor = QuadrantConstants.getQuadrantColor(quadrantType);
    final percent =
        totalCount > 0 ? (count / totalCount * 100).toStringAsFixed(1) : '0';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: quadrantColor.withValues(alpha: 0.5), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    QuadrantConstants.getQuadrantIcon(quadrantType),
                    color: quadrantColor,
                    size: 24,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: quadrantColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$percent%',
                      style: TextStyle(
                        color: quadrantColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                QuadrantConstants.getQuadrantName(quadrantType),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                QuadrantConstants.getQuadrantDescription(quadrantType),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: quadrantColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('任务', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
