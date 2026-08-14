/// 复盘记录——组织者=单人时标注单点风险；组织者变更自动提醒重新指定。
enum RetrospectiveStatus { scheduled, held, cancelled }

class Retrospective {
  const Retrospective({
    required this.id,
    required this.scheduleDate,
    required this.organizerId,
    this.participantIds = const [],
    this.conclusions = const [],
    this.status = RetrospectiveStatus.scheduled,
  });

  final String id;
  final String scheduleDate;
  final String organizerId;
  final List<String> participantIds;

  /// 结论沉淀（要点列表）。
  final List<String> conclusions;
  final RetrospectiveStatus status;
}
