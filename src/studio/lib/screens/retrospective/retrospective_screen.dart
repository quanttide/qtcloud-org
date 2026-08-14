import 'package:flutter/material.dart';

import '../../models/retrospective/retrospective.dart';
import '../../models/risk_item.dart';
import '../../sample_data.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/risk_badge.dart';
import '../../widgets/data/member_card.dart';
import '../../widgets/data/status_badge.dart';

/// 复盘页：复盘日程、记录与结论沉淀；组织者单点风险标注。
class RetrospectiveScreen extends StatefulWidget {
  const RetrospectiveScreen({super.key});

  @override
  State<RetrospectiveScreen> createState() => _RetrospectiveScreenState();
}

class _RetrospectiveScreenState extends State<RetrospectiveScreen> {
  final data = sampleData;
  late final List<Retrospective> _retrospectives = [...data.retrospectives];
  String? _selectedRetroId;

  Retrospective? get _selectedRetro => _selectedRetroId == null
      ? null
      : _retrospectives.where((r) => r.id == _selectedRetroId).firstOrNull;

  void _createRetrospective() {
    final dateController = TextEditingController(text: '2026-08-2X');
    final activeMembers = data.members
        .where((m) => !m.isDeparted)
        .toList(growable: false);
    String? organizerId = activeMembers.firstOrNull?.id;
    final selectedParticipants = <String>{};

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('新建复盘'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: '日程（YYYY-MM-DD）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: organizerId,
                decoration: const InputDecoration(
                  labelText: '组织者',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final member in activeMembers)
                    DropdownMenuItem(
                      value: member.id,
                      child: Text(member.name),
                    ),
                ],
                onChanged: (value) => setDialogState(() => organizerId = value),
              ),
              const SizedBox(height: 12),
              Text('参与人'),
              for (final member in activeMembers)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(member.name),
                  value: selectedParticipants.contains(member.id),
                  onChanged: (checked) => setDialogState(() {
                    if (checked == true) {
                      selectedParticipants.add(member.id);
                    } else {
                      selectedParticipants.remove(member.id);
                    }
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final id = 'retro-${_retrospectives.length + 1}';
                final retro = Retrospective(
                  id: id,
                  scheduleDate: dateController.text.trim(),
                  organizerId: organizerId ?? activeMembers.first.id,
                  participantIds: selectedParticipants.toList(),
                );
                setState(() {
                  _retrospectives.insert(0, retro);
                  _selectedRetroId = id;
                });
                Navigator.pop(context);
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('复盘'),
        actions: [
          IconButton(
            onPressed: _createRetrospective,
            icon: const Icon(Icons.add),
            tooltip: '新建复盘',
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 320,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (_retrospectives.isEmpty)
                  const EmptyState(
                    icon: Icons.assignment_outlined,
                    title: '暂无复盘',
                  )
                else
                  for (final retro in _retrospectives)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          selected: _selectedRetroId == retro.id,
                          leading: const Icon(Icons.event_note_outlined),
                          title: Text(retro.scheduleDate),
                          subtitle: Text(
                            '组织者：${data.memberById(retro.organizerId).name}'
                            ' · ${retro.status.name}',
                          ),
                          onTap: () =>
                              setState(() => _selectedRetroId = retro.id),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selectedRetro != null
                ? _RetroDetail(retro: _selectedRetro!, data: data)
                : const EmptyState(
                    icon: Icons.assignment_outlined,
                    title: '在左侧选择复盘查看详情',
                  ),
          ),
        ],
      ),
    );
  }
}

class _RetroDetail extends StatefulWidget {
  const _RetroDetail({required this.retro, required this.data});

  final Retrospective retro;
  final SampleData data;

  @override
  State<_RetroDetail> createState() => _RetroDetailState();
}

class _RetroDetailState extends State<_RetroDetail> {
  late final List<String> _conclusions = [...widget.retro.conclusions];
  final _conclusionController = TextEditingController();

  bool get _organizerIsSinglePoint =>
      widget.retro.status == RetrospectiveStatus.scheduled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final retro = widget.retro;
    final data = widget.data;
    final organizer = data.memberById(retro.organizerId);
    final participants = retro.participantIds
        .map(data.memberById)
        .toList(growable: false);
    final alternatives = data.members
        .where((m) => m.id != organizer.id && !m.isDeparted)
        .map((m) => m.name)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '复盘 · ${retro.scheduleDate}',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            StatusBadge(
              status: retro.status == RetrospectiveStatus.held
                  ? StatusBadgeStatus.normal
                  : StatusBadgeStatus.pending,
              label: retro.status.name,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MemberCard(
                member: organizer,
                positions: data.positionsOf(organizer),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('参与人', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final member in participants) Chip(label: Text(member.name)),
          ],
        ),
        if (participants.isEmpty)
          const EmptyState(icon: Icons.group_outlined, title: '尚未指定参与人'),
        const SizedBox(height: 24),
        Text('风险标注', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_organizerIsSinglePoint)
          RiskBadge(
            type: RiskType.organizerSingle,
            subject: '复盘组织者=单人（${organizer.name}）',
            alternatives: alternatives,
          )
        else
          const EmptyState(icon: Icons.verified_outlined, title: '无单点风险'),
        const SizedBox(height: 24),
        Text('结论沉淀', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_conclusions.isEmpty)
          const EmptyState(icon: Icons.notes_outlined, title: '暂无结论')
        else
          for (final conclusion in _conclusions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline, size: 18),
              title: Text(conclusion),
            ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _conclusionController,
                decoration: const InputDecoration(
                  hintText: '追加结论要点',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () {
                final text = _conclusionController.text.trim();
                if (text.isEmpty) return;
                setState(() {
                  _conclusions.add(text);
                  _conclusionController.clear();
                });
              },
              icon: const Icon(Icons.add),
              tooltip: '追加结论',
            ),
          ],
        ),
      ],
    );
  }
}
