import 'package:flutter/material.dart';

import '../../models/risk_item.dart';

/// 单点风险标注（岗位单人承担 / 岗位空缺 / 复盘组织者=单人）。
class RiskBadge extends StatelessWidget {
  const RiskBadge({
    super.key,
    required this.type,
    required this.subject,
    this.alternatives = const [],
  });

  final RiskType type;
  final String subject;
  final List<String> alternatives;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Colors.orange.shade800;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subject,
                  style: theme.textTheme.bodyMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
          if (alternatives.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                '备选：${alternatives.join('、')}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
