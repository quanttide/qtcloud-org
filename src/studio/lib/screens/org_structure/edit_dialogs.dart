import 'package:flutter/material.dart';

import '../../models/org/department.dart';
import '../../models/org/position.dart';

/// 上级选择中代表「顶层（无上级）」的哨兵值
const String _topLevel = '';

/// 新增部门草稿
class DepartmentDraft {
  const DepartmentDraft({required this.name, this.parentId});

  final String name;
  final String? parentId;
}

/// 岗位草稿（新增与编辑共用）
class PositionDraft {
  const PositionDraft({
    required this.name,
    required this.headcount,
    required this.departmentId,
  });

  final String name;
  final int headcount;
  final String departmentId;
}

/// 部门重命名；取消或空名返回 null。
Future<String?> showRenameDepartmentDialog(
  BuildContext context, {
  required String initialName,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        _NameDialog(title: '重命名部门', label: '部门名称', initial: initialName),
  );
}

/// 新增部门（名称 + 上级）；取消返回 null。
Future<DepartmentDraft?> showNewDepartmentDialog(
  BuildContext context, {
  required List<Department> parentOptions,
  String? initialParentId,
}) {
  return showDialog<DepartmentDraft>(
    context: context,
    builder: (_) => _NewDepartmentDialog(
      parentOptions: parentOptions,
      initialParentId: initialParentId,
    ),
  );
}

/// 调整上级部门；返回 `''` 表示改为顶层，返回 null 表示取消。
Future<String?> showParentDialog(
  BuildContext context, {
  required String departmentName,
  required List<Department> candidates,
  String? currentParentId,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ParentDialog(
      departmentName: departmentName,
      candidates: candidates,
      currentParentId: currentParentId,
    ),
  );
}

/// 新增或编辑岗位（`position` 非空为编辑）；取消返回 null。
Future<PositionDraft?> showPositionDialog(
  BuildContext context, {
  required List<Department> departments,
  required String initialDepartmentId,
  Position? position,
}) {
  return showDialog<PositionDraft>(
    context: context,
    builder: (_) => _PositionDialog(
      departments: departments,
      initialDepartmentId: initialDepartmentId,
      position: position,
    ),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.label,
    required this.initial,
  });

  final String title;
  final String label;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? '不能为空' : null,
            onFieldSubmitted: (_) => _confirm(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('确定')),
      ],
    );
  }
}

/// 新增部门：名称 + 上级（默认当前选中部门）
class _NewDepartmentDialog extends StatefulWidget {
  const _NewDepartmentDialog({
    required this.parentOptions,
    required this.initialParentId,
  });

  final List<Department> parentOptions;
  final String? initialParentId;

  @override
  State<_NewDepartmentDialog> createState() => _NewDepartmentDialogState();
}

class _NewDepartmentDialogState extends State<_NewDepartmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  late String _parentId = widget.initialParentId ?? _topLevel;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _controller.text.trim();
    Navigator.pop(
      context,
      DepartmentDraft(
        name: name,
        parentId: _parentId.isEmpty ? null : _parentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新增部门'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '部门名称',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? '不能为空' : null,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _parentId,
                decoration: const InputDecoration(
                  labelText: '上级部门',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: _topLevel,
                    child: Text('顶层（无上级）'),
                  ),
                  for (final dept in widget.parentOptions)
                    DropdownMenuItem(value: dept.id, child: Text(dept.name)),
                ],
                onChanged: (value) =>
                    setState(() => _parentId = value ?? _topLevel),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('确定')),
      ],
    );
  }
}

/// 调整上级：单选列表；`''` = 顶层
class _ParentDialog extends StatefulWidget {
  const _ParentDialog({
    required this.departmentName,
    required this.candidates,
    required this.currentParentId,
  });

  final String departmentName;
  final List<Department> candidates;
  final String? currentParentId;

  @override
  State<_ParentDialog> createState() => _ParentDialogState();
}

class _ParentDialogState extends State<_ParentDialog> {
  late String _parentId = widget.currentParentId ?? _topLevel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('调整上级部门 · ${widget.departmentName}'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: DropdownButtonFormField<String>(
            initialValue: _parentId,
            decoration: const InputDecoration(
              labelText: '上级部门',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: _topLevel,
                child: Text('顶层（无上级）'),
              ),
              for (final dept in widget.candidates)
                DropdownMenuItem(value: dept.id, child: Text(dept.name)),
            ],
            onChanged: (value) =>
                setState(() => _parentId = value ?? _topLevel),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _parentId),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// 新增/编辑岗位：名称 + 编制 + 所属部门
class _PositionDialog extends StatefulWidget {
  const _PositionDialog({
    required this.departments,
    required this.initialDepartmentId,
    this.position,
  });

  final List<Department> departments;
  final String initialDepartmentId;
  final Position? position;

  @override
  State<_PositionDialog> createState() => _PositionDialogState();
}

class _PositionDialogState extends State<_PositionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController(
    text: widget.position?.name ?? '',
  );
  late final TextEditingController _headcountController = TextEditingController(
    text: '${widget.position?.headcount ?? 1}',
  );
  late String _departmentId =
      widget.position?.departmentId ?? widget.initialDepartmentId;

  @override
  void dispose() {
    _nameController.dispose();
    _headcountController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      PositionDraft(
        name: _nameController.text.trim(),
        headcount: int.parse(_headcountController.text.trim()),
        departmentId: _departmentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.position != null;
    return AlertDialog(
      title: Text(editing ? '编辑岗位' : '新增岗位'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: '岗位名称',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value ?? '').trim().isEmpty ? '不能为空' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _headcountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '编制（人数）',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final count = int.tryParse((value ?? '').trim());
                        if (count == null || count < 1) {
                          return '编制为不小于 1 的整数';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _departmentId,
                decoration: const InputDecoration(
                  labelText: '所属部门',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final dept in widget.departments)
                    DropdownMenuItem(value: dept.id, child: Text(dept.name)),
                ],
                onChanged: (value) => setState(
                  () => _departmentId = value ?? _departmentId,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('确定')),
      ],
    );
  }
}
