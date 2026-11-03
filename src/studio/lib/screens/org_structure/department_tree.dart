import 'package:flutter/material.dart';

import '../../models/org/department.dart';
import '../../models/org/position.dart';

/// 部门 → 岗位 → 汇报链路的树形展示（架构页私有组件；已归档部门不展示）。
class DepartmentTree extends StatelessWidget {
  const DepartmentTree({
    super.key,
    required this.departments,
    required this.positions,
    this.selectedDepartmentId,
    this.selectedPositionId,
    this.onSelectDepartment,
    this.onSelectPosition,
  });

  final List<Department> departments;
  final List<Position> positions;
  final String? selectedDepartmentId;
  final String? selectedPositionId;
  final ValueChanged<String>? onSelectDepartment;
  final ValueChanged<String>? onSelectPosition;

  @override
  Widget build(BuildContext context) {
    final topLevel = departments
        .where((d) => d.parentId == null && d.status == DepartmentStatus.active)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [for (final dept in topLevel) _buildDepartment(dept)],
    );
  }

  Widget _buildDepartment(Department dept) {
    final subDepartments = departments
        .where(
          (d) => d.parentId == dept.id && d.status == DepartmentStatus.active,
        )
        .toList();
    final deptPositions = positions
        .where((p) => p.departmentId == dept.id)
        .toList();
    final children = <Widget>[
      for (final sub in subDepartments) _buildDepartment(sub),
      for (final position in deptPositions)
        ListTile(
          dense: true,
          selected: selectedPositionId == position.id,
          leading: const Icon(Icons.badge_outlined, size: 20),
          title: Text(position.name),
          subtitle: Text('${position.filled}/${position.headcount}'),
          trailing: position.isOverstaffed
              ? const Icon(Icons.warning_amber, size: 18, color: Colors.orange)
              : null,
          onTap: () => onSelectPosition?.call(position.id),
        ),
    ];
    return ExpansionTile(
      key: PageStorageKey(dept.id),
      initiallyExpanded: dept.parentId == null,
      leading: const Icon(Icons.account_tree_outlined),
      title: Text(dept.name),
      onExpansionChanged: (expanded) {
        if (expanded) onSelectDepartment?.call(dept.id);
      },
      children: children,
    );
  }
}
