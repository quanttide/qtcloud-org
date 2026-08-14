import 'package:flutter/material.dart';

import '../../models/change_record.dart';

/// 变更时间线面板（作者/时间/审批/提交 ID；不渲染 diff，diff 看数据层仓库提交）。
class ChangeHistoryPanel extends StatelessWidget {
  const ChangeHistoryPanel({super.key, required this.records});

  final List<ChangeRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final record in records) _RecordTile(record: record)],
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final ChangeRecord record;

  String get _approvalLabel => switch (record.approval) {
    ApprovalStatus.pending => '待审批',
    ApprovalStatus.approved => '已审批',
    ApprovalStatus.rejected => '已驳回',
    ApprovalStatus.auto => '自动',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(record.summary),
        subtitle: Text(
          '${record.authorId} · ${record.timestamp}'
          '${record.commitId != null ? ' · ${record.commitId}' : ''}',
          style: theme.textTheme.bodySmall,
        ),
        leading: Icon(switch (record.approval) {
          ApprovalStatus.pending => Icons.hourglass_top,
          ApprovalStatus.approved => Icons.check_circle_outline,
          ApprovalStatus.rejected => Icons.cancel_outlined,
          ApprovalStatus.auto => Icons.bolt_outlined,
        }, size: 20),
        trailing: Text(
          _approvalLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: record.approval == ApprovalStatus.pending
                ? Colors.blue.shade700
                : Colors.grey.shade600,
          ),
        ),
        children: [
          for (final change in record.changes)
            ListTile(
              dense: true,
              title: Text('${change.object}.${change.field}'),
              subtitle: Text(
                '${change.oldValue ?? '—'} → ${change.newValue ?? '—'}',
              ),
            ),
        ],
      ),
    );
  }
}
