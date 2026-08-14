import 'package:flutter/material.dart';

import '../../models/member/member.dart';
import '../../models/retrospective/retrospective.dart';
import '../../models/risk_item.dart';
import '../../sample_data.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/risk_badge.dart';
import '../../widgets/data/member_card.dart';
import '../../widgets/data/status_badge.dart';

/// 成员页：成员与职责查看中心 + 成员变动影响（岗位空缺/职责悬空）。
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final data = sampleData;
  String? _selectedMemberId;

  Member? get _selectedMember => _selectedMemberId == null
      ? null
      : data.members.where((m) => m.id == _selectedMemberId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeMembers = data.members
        .where((m) => !m.isDeparted)
        .toList(growable: false);
    final departedMembers = data.members
        .where((m) => m.isDeparted)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('成员与职责')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 320,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text('在职成员', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final member in activeMembers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MemberCard(
                      member: member,
                      positions: data.positionsOf(member),
                      onTap: () =>
                          setState(() => _selectedMemberId = member.id),
                    ),
                  ),
                if (departedMembers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('已离职成员', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  for (final member in departedMembers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MemberCard(
                        member: member,
                        positions: data.positionsOf(member),
                        onTap: () =>
                            setState(() => _selectedMemberId = member.id),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selectedMember != null
                ? _MemberDetail(member: _selectedMember!, data: data)
                : const EmptyState(
                    icon: Icons.people_outline,
                    title: '在左侧选择成员查看详情',
                  ),
          ),
        ],
      ),
    );
  }
}

class _MemberDetail extends StatelessWidget {
  const _MemberDetail({required this.member, required this.data});

  final Member member;
  final SampleData data;

  /// 该成员承担岗位的单点风险。
  List<RiskItem> get _positionRisks {
    final risks = <RiskItem>[];
    for (final position in data.positionsOf(member)) {
      if (position.isSinglePoint) {
        risks.add(
          RiskItem(
            type: RiskType.singlePoint,
            subject: '「${position.name}」仅一人承担',
          ),
        );
      }
    }
    return risks;
  }

  /// 该成员组织的复盘（组织者单点）。
  List<RiskItem> get _organizerRisks {
    final retros = data.retrospectives
        .where(
          (r) =>
              r.organizerId == member.id &&
              r.status == RetrospectiveStatus.scheduled,
        )
        .toList(growable: false);
    return retros.map((r) {
      final alternatives = data.members
          .where((m) => m.id != member.id && !m.isDeparted)
          .map((m) => m.name)
          .toList();
      return RiskItem(
        type: RiskType.organizerSingle,
        subject: '复盘组织者=单人',
        alternatives: alternatives,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final risks = [..._positionRisks, ..._organizerRisks];
    final positions = data.positionsOf(member);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(member.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          member.isDeparted ? '状态：已离职' : '状态：在职',
          style: theme.textTheme.bodyLarge,
        ),
        if (member.reportsToId != null) ...[
          const SizedBox(height: 4),
          Text(
            '汇报对象：${data.memberById(member.reportsToId!).name}',
            style: theme.textTheme.bodyLarge,
          ),
        ],
        const SizedBox(height: 16),
        Text('岗位（兼任 = 多个）', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final position in positions)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.badge_outlined),
            title: Text(position.name),
            subtitle: Text(data.departmentById(position.departmentId).name),
          ),
        if (positions.isEmpty)
          const EmptyState(icon: Icons.badge_outlined, title: '未任职岗位'),
        const SizedBox(height: 24),
        Text('风险标注', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (risks.isEmpty)
          const EmptyState(icon: Icons.verified_outlined, title: '无单点风险')
        else
          for (final risk in risks)
            RiskBadge(
              type: risk.type,
              subject: risk.subject,
              alternatives: risk.alternatives,
            ),
        if (member.isDeparted) _DepartedImpact(member: member, data: data),
      ],
    );
  }
}

/// 成员变动影响：离职成员遗留的岗位空缺与职责悬空（不实现交接流程）。
class _DepartedImpact extends StatelessWidget {
  const _DepartedImpact({required this.member, required this.data});

  final Member member;
  final SampleData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vacantPositions = data
        .positionsOf(member)
        .where((p) => p.isVacant)
        .toList(growable: false);
    final danglingRetros = data.retrospectives
        .where(
          (r) =>
              r.organizerId == member.id &&
              r.status == RetrospectiveStatus.scheduled,
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('成员变动影响', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusBadge(status: StatusBadgeStatus.risk, label: '需关注'),
                const SizedBox(height: 8),
                if (vacantPositions.isEmpty && danglingRetros.isEmpty)
                  const Text('无遗留空缺与悬空职责')
                else ...[
                  if (vacantPositions.isNotEmpty) ...[
                    Text('岗位空缺：', style: theme.textTheme.titleSmall),
                    for (final position in vacantPositions)
                      Text(
                        '· ${position.name}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 8),
                  ],
                  if (danglingRetros.isNotEmpty) ...[
                    Text('职责悬空：', style: theme.textTheme.titleSmall),
                    for (final retro in danglingRetros)
                      Text(
                        '· 复盘组织（${retro.scheduleDate}）——请重新指定组织者',
                        style: theme.textTheme.bodyMedium,
                      ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
