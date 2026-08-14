/// 成员——兼任 = 多个岗位；`departed` 由人事云事件经数据层写入。
enum MemberStatus { active, departed }

class Member {
  const Member({
    required this.id,
    required this.name,
    this.positions = const [],
    this.reportsToId,
    this.status = MemberStatus.active,
  });

  final String id;
  final String name;

  /// 岗位 id 列表（兼任 = 多个岗位）。
  final List<String> positions;

  /// 直接汇报对象。
  final String? reportsToId;
  final MemberStatus status;

  bool get isDeparted => status == MemberStatus.departed;
}
