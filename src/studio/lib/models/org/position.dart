/// 岗位（编制）——编制管控：变更走审批流，超编警示，冻结后不再新任职。
enum PositionStatus { active, frozen }

class Position {
  const Position({
    required this.id,
    required this.departmentId,
    required this.name,
    this.headcount = 1,
    this.filled = 0,
    this.status = PositionStatus.active,
  });

  final String id;
  final String departmentId;
  final String name;
  final int headcount;

  /// 已占用数（数据层派生，原型阶段由示例数据提供）。
  final int filled;
  final PositionStatus status;

  bool get isOverstaffed => filled > headcount;

  /// 岗位空缺：无人占用。
  bool get isVacant => filled == 0;

  /// 单点风险：编制 1 且仅 1 人承担，无备份设计。
  bool get isSinglePoint => filled == 1 && headcount == 1;
}
