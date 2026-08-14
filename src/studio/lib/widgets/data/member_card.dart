import 'package:flutter/material.dart';

import '../../models/member/member.dart';
import '../../models/org/position.dart';

/// 成员信息卡（姓名/岗位/汇报对象/兼任标注）。
class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.member,
    required this.positions,
    this.onTap,
  });

  final Member member;
  final List<Position> positions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final names = positions.map((p) => p.name).join(' / ');
    final isConcurrent = positions.length > 1;
    final colorScheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: member.isDeparted
              ? colorScheme.surfaceContainerHighest
              : colorScheme.primaryContainer,
          child: Text(
            member.name.characters.first,
            style: TextStyle(color: colorScheme.onPrimaryContainer),
          ),
        ),
        title: Row(
          children: [
            Text(member.name),
            if (member.isDeparted) ...[
              const SizedBox(width: 8),
              StatusTag(label: '已离职', color: colorScheme.outline),
            ],
          ],
        ),
        subtitle: Text(
          isConcurrent ? '$names（兼任）' : (names.isEmpty ? '未任职' : names),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// 页面私有小标签（避免为单处样式引入通用组件）。
class StatusTag extends StatelessWidget {
  const StatusTag({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
