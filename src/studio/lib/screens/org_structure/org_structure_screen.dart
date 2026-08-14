import 'package:flutter/material.dart';

import '../../models/change_record.dart';
import '../../models/org/department.dart';
import '../../models/org/position.dart';
import '../../sample_data.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/data/status_badge.dart';
import 'change_history_panel.dart';
import 'department_tree.dart';

/// 架构页：组织架构的浏览与变更入口（唯一权威源的可视化）。
class OrgStructureScreen extends StatefulWidget {
  const OrgStructureScreen({super.key});

  @override
  State<OrgStructureScreen> createState() => _OrgStructureScreenState();
}

class _OrgStructureScreenState extends State<OrgStructureScreen> {
  final data = sampleData;
  late final List<ChangeRecord> _changes = [...data.changeRecords];

  String? _selectedDepartmentId;
  String? _selectedPositionId;

  Department? get _selectedDepartment => _selectedDepartmentId == null
      ? null
      : data.departments
            .where((d) => d.id == _selectedDepartmentId)
            .firstOrNull;

  Position? get _selectedPosition => _selectedPositionId == null
      ? null
      : data.positions.where((p) => p.id == _selectedPositionId).firstOrNull;

  void _submitChange() {
    final position = _selectedPosition;
    if (position == null) return;
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发起变更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '对象：${position.name}（${position.filled}/${position.headcount}）',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '变更说明（改什么、为什么）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              final summary = controller.text.trim().isEmpty
                  ? '变更：${position.name}'
                  : controller.text.trim();
              setState(() {
                _changes.insert(
                  0,
                  ChangeRecord(
                    id: 'change-${_changes.length + 1}',
                    authorId: 'member-zhang',
                    timestamp: DateTime.now().toIso8601String(),
                    approval: ApprovalStatus.pending,
                    summary: summary,
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('提交（进入审批流）'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('组织架构')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 300,
            child: DepartmentTree(
              departments: data.departments,
              positions: data.positions,
              selectedDepartmentId: _selectedDepartmentId,
              selectedPositionId: _selectedPositionId,
              onSelectDepartment: (id) => setState(() {
                _selectedDepartmentId = id;
                _selectedPositionId = null;
              }),
              onSelectPosition: (id) => setState(() {
                _selectedPositionId = id;
                _selectedDepartmentId = null;
              }),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selectedPosition != null
                ? _PositionDetail(
                    position: _selectedPosition!,
                    data: data,
                    records: _changes,
                  )
                : _DepartmentDetail(
                    department: _selectedDepartment,
                    data: data,
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedPosition != null
          ? FloatingActionButton.extended(
              onPressed: _submitChange,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('发起变更'),
            )
          : null,
    );
  }
}

/// 岗位详情面板（含编制与汇报链路）。
class _PositionDetail extends StatelessWidget {
  const _PositionDetail({
    required this.position,
    required this.data,
    required this.records,
  });

  final Position position;
  final SampleData data;
  final List<ChangeRecord> records;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final department = data.departmentById(position.departmentId);
    final holders = data.membersOfPosition(position);
    final relations = data.reportRelations
        .where((r) => r.positionId == position.id && r.active)
        .toList();

    final badge = position.isOverstaffed
        ? const StatusBadge(status: StatusBadgeStatus.risk, label: '超编')
        : position.isVacant
        ? const StatusBadge(status: StatusBadgeStatus.risk, label: '空缺')
        : const StatusBadge(status: StatusBadgeStatus.normal, label: '正常');

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(position.name, style: theme.textTheme.headlineSmall),
            ),
            badge,
          ],
        ),
        const SizedBox(height: 8),
        Text('所属部门：${department.name}', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        _HeadcountTable(position: position),
        const SizedBox(height: 24),
        Text('任职成员', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (holders.isEmpty)
          const EmptyState(icon: Icons.person_off_outlined, title: '岗位空缺，待指定成员')
        else
          for (final member in holders)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(member.name),
            ),
        const SizedBox(height: 24),
        Text('汇报链路', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final relation in relations)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.subdirectory_arrow_right),
            title: Text(
              '${data.memberById(relation.memberId).name} → '
              '${_reportsToLabel(relation.reportsToId, data)}',
            ),
          ),
        const SizedBox(height: 24),
        Text('版本历史', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ChangeHistoryPanel(records: records),
      ],
    );
  }

  String _reportsToLabel(String id, SampleData data) {
    final members = data.members.where((m) => m.id == id);
    if (members.isNotEmpty) return members.first.name;
    final departments = data.departments.where((d) => d.id == id);
    if (departments.isNotEmpty) return departments.first.name;
    return id;
  }
}

/// 部门详情面板（含编制表）。
class _DepartmentDetail extends StatelessWidget {
  const _DepartmentDetail({required this.department, required this.data});

  final Department? department;
  final SampleData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (department == null) {
      return const EmptyState(
        icon: Icons.account_tree_outlined,
        title: '在左侧选择部门或岗位查看详情',
      );
    }
    final dept = department!;
    final deptPositions = data.positions
        .where((p) => p.departmentId == dept.id)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(dept.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (dept.leaderId != null)
          Text(
            '负责人：${data.memberById(dept.leaderId!).name}',
            style: theme.textTheme.bodyLarge,
          ),
        if (dept.parentId != null)
          Text(
            '上级部门：${data.departmentById(dept.parentId!).name}',
            style: theme.textTheme.bodyLarge,
          ),
        const SizedBox(height: 16),
        Text('编制表', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _HeadcountTable(positions: deptPositions),
      ],
    );
  }
}

/// 编制表（架构页私有组件，原 TableCard 降级）。
class _HeadcountTable extends StatelessWidget {
  const _HeadcountTable({this.position, this.positions});

  /// 单个岗位视图（横向排布）。
  final Position? position;

  /// 部门视图（表格）。
  final List<Position>? positions;

  @override
  Widget build(BuildContext context) {
    if (position != null) {
      return _singleRow(position!);
    }
    final rows = positions ?? const <Position>[];
    if (rows.isEmpty) {
      return const EmptyState(
        icon: Icons.table_rows_outlined,
        title: '该部门暂无岗位',
      );
    }
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(2),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
          children: [
            _Cell('岗位', bold: true),
            _Cell('编制', bold: true),
            _Cell('已占用', bold: true),
            _Cell('状态', bold: true),
          ],
        ),
        for (final p in rows)
          TableRow(
            children: [
              _Cell(p.name),
              _Cell('${p.headcount}'),
              _Cell('${p.filled}'),
              _Cell(
                p.isOverstaffed ? '超编' : (p.isVacant ? '空缺' : '正常'),
                color: (p.isOverstaffed || p.isVacant)
                    ? Colors.orange.shade800
                    : null,
              ),
            ],
          ),
      ],
    );
  }

  Widget _singleRow(Position p) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          children: [
            _Cell('编制：${p.headcount}', bold: true),
            _Cell('已占用：${p.filled}', bold: true),
            _Cell(
              p.isOverstaffed ? '超编' : (p.isVacant ? '空缺' : '正常'),
              color: (p.isOverstaffed || p.isVacant)
                  ? Colors.orange.shade800
                  : null,
            ),
            _Cell(p.status == PositionStatus.frozen ? '冻结' : '启用'),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.bold = false, this.color});

  final String text;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}
