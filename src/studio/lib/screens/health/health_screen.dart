import 'package:flutter/material.dart';

import '../../models/health/health_report.dart';
import '../../models/retrospective/retrospective.dart';
import '../../models/risk_item.dart';
import '../../sample_data.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/risk_badge.dart';
import '../../widgets/data/member_card.dart';
import '../../widgets/data/status_badge.dart';

/// 组织健康度页：OHI 九维度体检（组织温度计）+ 复盘记录（机制健康数据源）。
class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('组织健康度'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '健康度总览'),
              Tab(text: '复盘记录'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_HealthOverviewTab(), _RetrospectiveTab()],
        ),
      ),
    );
  }
}

/// 复盘状态的中文标签与徽章样式。
String _statusLabel(RetrospectiveStatus status) => switch (status) {
  RetrospectiveStatus.scheduled => '待召开',
  RetrospectiveStatus.held => '已召开',
  RetrospectiveStatus.cancelled => '已取消',
};

StatusBadgeStatus _statusBadge(RetrospectiveStatus status) => switch (status) {
  RetrospectiveStatus.scheduled => StatusBadgeStatus.pending,
  RetrospectiveStatus.held ||
  RetrospectiveStatus.cancelled => StatusBadgeStatus.normal,
};

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------------------
// Tab 1：健康度总览（组织温度计 + OHI 九维度）
// ---------------------------------------------------------------------------

class _HealthOverviewTab extends StatelessWidget {
  const _HealthOverviewTab();

  @override
  Widget build(BuildContext context) {
    final report = sampleData.healthReport;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _ThermometerCard(report: report),
        const SizedBox(height: 16),
        Text(
          'OHI 九维度（McKinsey 组织健康指数，量潮适配版）',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '维度指标由组织数据推导，分级约定见 data/context/handbook/health.md',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 12),
        for (final dimension in report.dimensions)
          _DimensionCard(dimension: dimension),
      ],
    );
  }
}

/// 组织温度计（页面私有组件）。
class _ThermometerCard extends StatelessWidget {
  const _ThermometerCard({required this.report});

  final HealthReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overall = report.overall;
    final color = switch (overall) {
      HealthLevel.good => Colors.green.shade700,
      HealthLevel.warning => Colors.orange.shade800,
      HealthLevel.risk => Colors.red.shade700,
      HealthLevel.notAssessed => Colors.grey.shade600,
    };
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.thermostat, color: color),
                const SizedBox(width: 8),
                Text('组织温度计', style: theme.textTheme.titleMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.overall == HealthLevel.notAssessed
                        ? '未评估'
                        : '整体${overall.label}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${report.temperature.toStringAsFixed(1)}°C',
              style: theme.textTheme.displaySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: report.score / 3,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '已评估 8 维 · 良好 ${report.goodCount} / 注意 ${report.warningCount}'
              ' / 警示 ${report.riskCount} · 待问卷 ${report.notAssessedCount}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on HealthLevel {
  String get label => switch (this) {
    HealthLevel.good => '良好',
    HealthLevel.warning => '注意',
    HealthLevel.risk => '警示',
    HealthLevel.notAssessed => '待问卷',
  };
}

class _DimensionCard extends StatelessWidget {
  const _DimensionCard({required this.dimension});

  final HealthDimension dimension;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (dimension.level) {
      HealthLevel.good => Colors.green.shade700,
      HealthLevel.warning => Colors.orange.shade800,
      HealthLevel.risk => Colors.red.shade700,
      HealthLevel.notAssessed => Colors.grey.shade600,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${dimension.name} ${dimension.englishName}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(dimension.description),
            Text(
              dimension.indicator,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            dimension.levelLabel,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2：复盘记录（机制健康数据源）
// ---------------------------------------------------------------------------

class _RetrospectiveTab extends StatefulWidget {
  const _RetrospectiveTab();

  @override
  State<_RetrospectiveTab> createState() => _RetrospectiveTabState();
}

class _RetrospectiveTabState extends State<_RetrospectiveTab> {
  final data = sampleData;
  late final List<Retrospective> _retrospectives = [...data.retrospectives];
  String? _selectedRetroId;

  Retrospective? get _selectedRetro => _selectedRetroId == null
      ? null
      : _retrospectives.where((r) => r.id == _selectedRetroId).firstOrNull;

  void _updateRetro(Retrospective updated) {
    setState(() {
      final index = _retrospectives.indexWhere((r) => r.id == updated.id);
      if (index != -1) _retrospectives[index] = updated;
    });
  }

  void _deleteRetro(String id) {
    setState(() {
      _retrospectives.removeWhere((r) => r.id == id);
      if (_selectedRetroId == id) _selectedRetroId = null;
    });
  }

  /// 新建 / 编辑复盘（同一对话框，编辑时预填）。
  Future<void> _openEditor({Retrospective? existing}) async {
    final activeMembers = data.members
        .where((m) => !m.isDeparted)
        .toList(growable: false);
    var organizerId = existing?.organizerId ?? activeMembers.firstOrNull?.id;
    final dateController = TextEditingController(
      text: existing?.scheduleDate ?? _formatDate(DateTime.now()),
    );
    final participantIds = <String>{...?existing?.participantIds};

    final result =
        await showDialog<
          ({
            String scheduleDate,
            String organizerId,
            List<String> participantIds,
          })
        >(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(existing == null ? '新建复盘' : '编辑复盘'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: dateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: '日程',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.event),
                        ),
                        onTap: () async {
                          final parsed =
                              DateTime.tryParse(dateController.text) ??
                              DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: parsed,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              dateController.text = _formatDate(picked);
                            });
                          }
                        },
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
                        onChanged: (value) =>
                            setDialogState(() => organizerId = value),
                      ),
                      const SizedBox(height: 12),
                      Text('参与人'),
                      for (final member in activeMembers)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(member.name),
                          value: participantIds.contains(member.id),
                          onChanged: (checked) => setDialogState(() {
                            if (checked == true) {
                              participantIds.add(member.id);
                            } else {
                              participantIds.remove(member.id);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final date = dateController.text.trim();
                      if (date.isEmpty || organizerId == null) return;
                      Navigator.pop(context, (
                        scheduleDate: date,
                        organizerId: organizerId!,
                        participantIds: participantIds.toList(),
                      ));
                    },
                    child: Text(existing == null ? '创建' : '保存'),
                  ),
                ],
              );
            },
          ),
        );
    if (result == null) return;

    if (existing == null) {
      final retro = Retrospective(
        id: 'retro-${_retrospectives.length + 1}',
        scheduleDate: result.scheduleDate,
        organizerId: result.organizerId,
        participantIds: result.participantIds,
      );
      setState(() {
        _retrospectives.insert(0, retro);
        _selectedRetroId = retro.id;
      });
    } else {
      _updateRetro(
        Retrospective(
          id: existing.id,
          scheduleDate: result.scheduleDate,
          organizerId: result.organizerId,
          participantIds: result.participantIds,
          conclusions: existing.conclusions,
          status: existing.status,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 320,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '复盘记录',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: _openEditor,
                    icon: const Icon(Icons.add),
                    tooltip: '新建复盘',
                  ),
                ],
              ),
              if (_retrospectives.isEmpty)
                const EmptyState(icon: Icons.assignment_outlined, title: '暂无复盘')
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
                          ' · 参与 ${retro.participantIds.length} 人'
                          ' · ${_statusLabel(retro.status)}',
                        ),
                        trailing: retro.status == RetrospectiveStatus.scheduled
                            ? const Icon(Icons.chevron_right)
                            : null,
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
              ? _RetroDetail(
                  retro: _selectedRetro!,
                  data: data,
                  onUpdate: _updateRetro,
                  onDelete: _deleteRetro,
                  onEdit: () => _openEditor(existing: _selectedRetro),
                )
              : const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: '在左侧选择复盘查看详情',
                ),
        ),
      ],
    );
  }
}

class _RetroDetail extends StatelessWidget {
  const _RetroDetail({
    required this.retro,
    required this.data,
    required this.onUpdate,
    required this.onDelete,
    required this.onEdit,
  });

  final Retrospective retro;
  final SampleData data;
  final ValueChanged<Retrospective> onUpdate;
  final ValueChanged<String> onDelete;
  final VoidCallback onEdit;

  bool get _isScheduled => retro.status == RetrospectiveStatus.scheduled;

  /// 组织者已离职：提醒重新指定（组织者变更自动提醒的落点）。
  bool get _organizerDeparted => data.memberById(retro.organizerId).isDeparted;

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除复盘'),
        content: Text('确定删除「${retro.scheduleDate}」的复盘？结论沉淀将一并移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              onDelete(retro.id);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _appendConclusion(String text) {
    onUpdate(
      Retrospective(
        id: retro.id,
        scheduleDate: retro.scheduleDate,
        organizerId: retro.organizerId,
        participantIds: retro.participantIds,
        conclusions: [...retro.conclusions, text],
        status: retro.status,
      ),
    );
  }

  void _removeConclusion(int index) {
    onUpdate(
      Retrospective(
        id: retro.id,
        scheduleDate: retro.scheduleDate,
        organizerId: retro.organizerId,
        participantIds: retro.participantIds,
        conclusions: [
          for (final (i, conclusion) in retro.conclusions.indexed)
            if (i != index) conclusion,
        ],
        status: retro.status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final organizer = data.memberById(retro.organizerId);
    final participants = retro.participantIds.map(data.memberById).toList();
    final alternatives = data.members
        .where((m) => m.id != organizer.id && !m.isDeparted)
        .map((m) => m.name)
        .toList();
    final conclusionController = TextEditingController();

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
              status: _statusBadge(retro.status),
              label: _statusLabel(retro.status),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isScheduled)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => onUpdate(
                  Retrospective(
                    id: retro.id,
                    scheduleDate: retro.scheduleDate,
                    organizerId: retro.organizerId,
                    participantIds: retro.participantIds,
                    conclusions: retro.conclusions,
                    status: RetrospectiveStatus.held,
                  ),
                ),
                icon: const Icon(Icons.check),
                label: const Text('标记已召开'),
              ),
              OutlinedButton.icon(
                onPressed: () => onUpdate(
                  Retrospective(
                    id: retro.id,
                    scheduleDate: retro.scheduleDate,
                    organizerId: retro.organizerId,
                    participantIds: retro.participantIds,
                    conclusions: retro.conclusions,
                    status: RetrospectiveStatus.cancelled,
                  ),
                ),
                icon: const Icon(Icons.event_busy),
                label: const Text('取消复盘'),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('编辑'),
              ),
              TextButton.icon(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('删除'),
              ),
            ],
          )
        else
          Row(
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('编辑'),
              ),
              TextButton.icon(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('删除'),
              ),
            ],
          ),
        if (_organizerDeparted && _isScheduled) ...[
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
            child: ListTile(
              leading: Icon(
                Icons.person_off_outlined,
                color: theme.colorScheme.error,
              ),
              title: Text(
                '组织者 ${organizer.name} 已离职——请重新指定组织者',
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
              trailing: FilledButton.tonal(
                onPressed: onEdit,
                child: const Text('立即指定'),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
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
        if (participants.isEmpty)
          const EmptyState(icon: Icons.group_outlined, title: '尚未指定参与人')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final member in participants)
                Chip(
                  label: Text(
                    member.isDeparted ? '${member.name}（已离职）' : member.name,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 24),
        Text('风险标注', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_isScheduled)
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
        if (retro.conclusions.isEmpty)
          const EmptyState(icon: Icons.notes_outlined, title: '暂无结论')
        else
          for (final (index, conclusion) in retro.conclusions.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline, size: 18),
              title: Text(conclusion),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: '删除结论',
                onPressed: () => _removeConclusion(index),
              ),
            ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: conclusionController,
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
                final text = conclusionController.text.trim();
                if (text.isEmpty) return;
                _appendConclusion(text);
                conclusionController.clear();
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
