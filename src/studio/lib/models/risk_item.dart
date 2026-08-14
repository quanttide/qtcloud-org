/// 风险条目——首页聚合与成员页标注的数据结构。
enum RiskType {
  /// 岗位仅一人承担（编制 1 且仅 1 人）。
  singlePoint,

  /// 岗位空缺（无人占用）。
  vacancy,

  /// 复盘组织者=单人。
  organizerSingle,
}

class RiskItem {
  const RiskItem({
    required this.type,
    required this.subject,
    this.alternatives = const [],
  });

  final RiskType type;
  final String subject;

  /// 备选提示（提示备选人）。
  final List<String> alternatives;
}
