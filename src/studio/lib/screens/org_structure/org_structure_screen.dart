import 'package:flutter/material.dart';

import '../../models/change_record.dart';
import '../../models/org/department.dart';
import '../../models/org/position.dart';
import '../../sample_data.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/data/status_badge.dart';
import 'change_history_panel.dart';
import 'department_tree.dart';
import 'edit_dialogs.dart';

/// 架构页：组织架构的浏览与变更入口（唯一权威源的可视化）。
class OrgStructureScreen extends StatefulWidget {
  const OrgStructureScreen({super.key});

  @override
  State<OrgStructureScreen> createState() => _OrgStructureScreenState();
}

class _OrgStructureScreenState extends State<OrgStructureScreen> {
  final data = sampleData;

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
                data.changeRecords.insert(
                  0,
                  ChangeRecord(
                    id: 'change-${DateTime.now().microsecondsSinceEpoch}',
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

  // ── 架构编辑：写操作直接生效并落 ChangeRecord（approval: auto） ──

  List<Department> get _activeDepartments => data.departments
      .where((d) => d.status == DepartmentStatus.active)
      .toList();

  String _deptName(String? id) => id == null
      ? '顶层'
      : data.departments
                    .where((d) => d.id == id)
                    .map((d) => d.name)
                    .firstOrNull ??
                id;

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  void _toast(String message) {
    // 连续操作时旧提示立即让位，避免提示排队堆叠
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _record(String summary, List<Change> changes) {
    data.changeRecords.insert(
      0,
      ChangeRecord(
        id: _newId('change'),
        authorId: 'member-zhang',
        timestamp: DateTime.now().toIso8601String(),
        approval: ApprovalStatus.auto,
        summary: summary,
        changes: changes,
      ),
    );
  }

  void _replaceDepartment(Department updated) {
    final index = data.departments.indexWhere((d) => d.id == updated.id);
    if (index >= 0) data.departments[index] = updated;
  }

  void _replacePosition(Position updated) {
    final index = data.positions.indexWhere((p) => p.id == updated.id);
    if (index >= 0) data.positions[index] = updated;
  }

  /// 部门及其全部下级（调整上级时禁止挂到自身或下级下）。
  Set<String> _subtreeIds(String rootId) {
    final ids = <String>{rootId};
    var grew = true;
    while (grew) {
      grew = false;
      for (final dept in data.departments) {
        if (dept.parentId != null &&
            ids.contains(dept.parentId) &&
            !ids.contains(dept.id)) {
          ids.add(dept.id);
          grew = true;
        }
      }
    }
    return ids;
  }

  Future<void> _addDepartment() async {
    final draft = await showNewDepartmentDialog(
      context,
      parentOptions: _activeDepartments,
      initialParentId: _selectedDepartmentId,
    );
    if (draft == null) return;
    setState(() {
      final id = _newId('dept');
      data.departments.add(
        Department(id: id, name: draft.name, parentId: draft.parentId),
      );
      _record(
        '新增部门「${draft.name}」',
        [Change(object: 'Department', field: 'name', newValue: draft.name)],
      );
      _selectedDepartmentId = id;
      _selectedPositionId = null;
    });
    _toast('已新增部门「${draft.name}」');
  }

  Future<void> _addPosition() async {
    final departments = _activeDepartments;
    if (departments.isEmpty) {
      _toast('先新增部门，再新增岗位');
      return;
    }
    final initialDepartmentId =
        _selectedPosition?.departmentId ??
        _selectedDepartmentId ??
        departments.first.id;
    final draft = await showPositionDialog(
      context,
      departments: departments,
      initialDepartmentId: initialDepartmentId,
    );
    if (draft == null) return;
    setState(() {
      final id = _newId('pos');
      data.positions.add(
        Position(
          id: id,
          departmentId: draft.departmentId,
          name: draft.name,
          headcount: draft.headcount,
        ),
      );
      _record(
        '新增岗位「${draft.name}」编制 ${draft.headcount}'
        '（${_deptName(draft.departmentId)}）',
        [
          Change(
            object: 'Position',
            field: 'headcount',
            newValue: '${draft.headcount}',
          ),
        ],
      );
      _selectedPositionId = id;
      _selectedDepartmentId = null;
    });
    _toast('已新增岗位「${draft.name}」');
  }

  Future<void> _renameDepartment(Department department) async {
    final name = await showRenameDepartmentDialog(
      context,
      initialName: department.name,
    );
    if (name == null || name == department.name) return;
    setState(() {
      _replaceDepartment(
        Department(
          id: department.id,
          name: name,
          parentId: department.parentId,
          leaderId: department.leaderId,
          status: department.status,
        ),
      );
      _record(
        '部门「${department.name}」重命名为「$name」',
        [
          Change(
            object: 'Department',
            field: 'name',
            oldValue: department.name,
            newValue: name,
          ),
        ],
      );
    });
    _toast('已重命名为「$name」');
  }

  Future<void> _moveDepartment(Department department) async {
    final excluded = _subtreeIds(department.id);
    final candidates = _activeDepartments
        .where((dept) => !excluded.contains(dept.id))
        .toList();
    final picked = await showParentDialog(
      context,
      departmentName: department.name,
      candidates: candidates,
      currentParentId: department.parentId,
    );
    if (picked == null) return;
    final parentId = picked.isEmpty ? null : picked;
    if (parentId == department.parentId) return;
    setState(() {
      _replaceDepartment(
        Department(
          id: department.id,
          name: department.name,
          parentId: parentId,
          leaderId: department.leaderId,
          status: department.status,
        ),
      );
      _record(
        '「${department.name}」上级部门：'
        '${_deptName(department.parentId)} → ${_deptName(parentId)}',
        [
          Change(
            object: 'Department',
            field: 'parentId',
            oldValue: _deptName(department.parentId),
            newValue: _deptName(parentId),
          ),
        ],
      );
    });
    _toast('已调整「${department.name}」的上级部门');
  }

  Future<void> _deleteDepartment(Department department) async {
    final hasChildren = data.departments.any(
      (dept) =>
          dept.parentId == department.id &&
          dept.status == DepartmentStatus.active,
    );
    if (hasChildren) {
      _toast('「${department.name}」下有子部门，先移动或删除子部门');
      return;
    }
    final hasPositions = data.positions.any(
      (position) => position.departmentId == department.id,
    );
    if (hasPositions) {
      _toast('「${department.name}」下有岗位，先移动或删除岗位');
      return;
    }
    final confirmed = await _confirmDialog(
      title: '删除部门',
      message: '「${department.name}」将从架构中移除，变更留痕可查。确认删除？',
      confirmLabel: '删除',
    );
    if (confirmed != true) return;
    setState(() {
      _replaceDepartment(
        Department(
          id: department.id,
          name: department.name,
          parentId: department.parentId,
          leaderId: department.leaderId,
          status: DepartmentStatus.archived,
        ),
      );
      _record(
        '删除部门「${department.name}」',
        [
          Change(
            object: 'Department',
            field: 'status',
            oldValue: 'active',
            newValue: 'archived',
          ),
        ],
      );
      if (_selectedDepartmentId == department.id) {
        _selectedDepartmentId = null;
      }
    });
    _toast('已删除部门「${department.name}」');
  }

  Future<void> _editPosition(Position position) async {
    final draft = await showPositionDialog(
      context,
      departments: _activeDepartments,
      initialDepartmentId: position.departmentId,
      position: position,
    );
    if (draft == null) return;
    final changes = <Change>[];
    if (draft.name != position.name) {
      changes.add(
        Change(
          object: 'Position',
          field: 'name',
          oldValue: position.name,
          newValue: draft.name,
        ),
      );
    }
    if (draft.headcount != position.headcount) {
      changes.add(
        Change(
          object: 'Position',
          field: 'headcount',
          oldValue: '${position.headcount}',
          newValue: '${draft.headcount}',
        ),
      );
    }
    if (draft.departmentId != position.departmentId) {
      changes.add(
        Change(
          object: 'Position',
          field: 'departmentId',
          oldValue: _deptName(position.departmentId),
          newValue: _deptName(draft.departmentId),
        ),
      );
    }
    if (changes.isEmpty) return;
    setState(() {
      _replacePosition(
        Position(
          id: position.id,
          departmentId: draft.departmentId,
          name: draft.name,
          headcount: draft.headcount,
          filled: position.filled,
          status: position.status,
        ),
      );
      _record('编辑岗位「${position.name}」', changes);
    });
    _toast('已更新岗位「${draft.name}」');
  }

  Future<void> _deletePosition(Position position) async {
    final referenced = data.members.any(
      (member) => member.positions.contains(position.id),
    );
    if (referenced) {
      _toast('「${position.name}」仍挂在成员名下，先解除任职再删除');
      return;
    }
    final confirmed = await _confirmDialog(
      title: '删除岗位',
      message: '「${position.name}」（编制 ${position.headcount}）将被移除。确认删除？',
      confirmLabel: '删除',
    );
    if (confirmed != true) return;
    setState(() {
      data.positions.removeWhere((p) => p.id == position.id);
      _record(
        '删除岗位「${position.name}」',
        [
          Change(
            object: 'Position',
            field: 'status',
            oldValue: 'active',
            newValue: 'deleted',
          ),
        ],
      );
      if (_selectedPositionId == position.id) {
        _selectedPositionId = null;
      }
    });
    _toast('已删除岗位「${position.name}」');
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('组织架构'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: '新增部门',
            onPressed: _addDepartment,
          ),
          IconButton(
            icon: const Icon(Icons.post_add_outlined),
            tooltip: '新增岗位',
            onPressed: _addPosition,
          ),
          if (_selectedDepartment != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: '部门操作',
              onSelected: (action) {
                final department = _selectedDepartment!;
                switch (action) {
                  case 'rename':
                    _renameDepartment(department);
                  case 'move':
                    _moveDepartment(department);
                  case 'delete':
                    _deleteDepartment(department);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('重命名部门')),
                PopupMenuItem(value: 'move', child: Text('调整上级部门')),
                PopupMenuItem(value: 'delete', child: Text('删除部门')),
              ],
            ),
          if (_selectedPosition != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: '岗位操作',
              onSelected: (action) {
                final position = _selectedPosition!;
                switch (action) {
                  case 'edit':
                    _editPosition(position);
                  case 'delete':
                    _deletePosition(position);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('编辑岗位')),
                PopupMenuItem(value: 'delete', child: Text('删除岗位')),
              ],
            ),
        ],
      ),
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
                    records: data.changeRecords,
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
