/// 部门——编制/归属的唯一权威源。
enum DepartmentStatus { active, archived }

class Department {
  const Department({
    required this.id,
    required this.name,
    this.parentId,
    this.leaderId,
    this.status = DepartmentStatus.active,
  });

  final String id;
  final String name;
  final String? parentId;
  final String? leaderId;
  final DepartmentStatus status;
}
