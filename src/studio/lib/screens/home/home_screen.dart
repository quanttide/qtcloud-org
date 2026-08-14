import 'package:flutter/material.dart';

import '../../models/change_record.dart';
import '../../sample_data.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/risk_badge.dart';
import '../../widgets/data/status_badge.dart';

/// 工作台总览：待审批变更 / 风险清单 / 岗位空缺聚合（必读处入口）。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = sampleData;
    final pending = data.pendingChanges;
    final risks = data.risks;
    final vacancies = data.positions
        .where((p) => p.isVacant)
        .toList(growable: false);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('量潮组织云')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('今日组织云状态', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '记录与复盘的必读处——风险与空缺在此聚合',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: '待审批变更',
            icon: Icons.hourglass_top,
            trailing: _CountBadge(count: pending.length),
            children: pending.isEmpty
                ? [
                    const EmptyState(
                      icon: Icons.check_circle_outline,
                      title: '暂无待审批变更',
                    ),
                  ]
                : [
                    for (final record in pending)
                      _PendingChangeTile(record: record),
                  ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: '风险清单',
            icon: Icons.warning_amber_rounded,
            trailing: _CountBadge(count: risks.length),
            children: risks.isEmpty
                ? [
                    const EmptyState(
                      icon: Icons.verified_outlined,
                      title: '一切正常',
                    ),
                  ]
                : [
                    for (final risk in risks)
                      RiskBadge(
                        type: risk.type,
                        subject: risk.subject,
                        alternatives: risk.alternatives,
                      ),
                  ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: '岗位空缺',
            icon: Icons.person_off_outlined,
            trailing: _CountBadge(count: vacancies.length),
            children: vacancies.isEmpty
                ? [
                    const EmptyState(
                      icon: Icons.groups_outlined,
                      title: '无岗位空缺',
                    ),
                  ]
                : [
                    for (final position in vacancies)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.badge_outlined),
                        title: Text(position.name),
                        subtitle: Text(
                          data.departmentById(position.departmentId).name,
                        ),
                      ),
                  ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.trailing,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Widget trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$count',
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

class _PendingChangeTile extends StatelessWidget {
  const _PendingChangeTile({required this.record});

  final ChangeRecord record;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.edit_note),
      title: Text(record.summary),
      subtitle: Text(record.timestamp),
      trailing: const StatusBadge(
        status: StatusBadgeStatus.pending,
        label: '待审批',
      ),
    );
  }
}
