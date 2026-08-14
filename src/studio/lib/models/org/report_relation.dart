/// 汇报链路——一人多岗时每个岗位各自一条关系，链路可追溯。
class ReportRelation {
  const ReportRelation({
    required this.id,
    required this.memberId,
    required this.positionId,
    required this.reportsToId,
    this.active = true,
  });

  final String id;
  final String memberId;
  final String positionId;

  /// 汇报对象（成员 id 或组织 id）。
  final String reportsToId;
  final bool active;
}
