import '../change_record.dart';
import '../member/member.dart';
import '../org/position.dart';
import '../org/report_relation.dart';
import '../retrospective/retrospective.dart';

/// 健康度等级。
enum HealthLevel { good, warning, risk, notAssessed }

/// OHI 健康度维度（McKinsey 组织健康指数九维度，量潮适配版）。
class HealthDimension {
  const HealthDimension({
    required this.id,
    required this.name,
    required this.englishName,
    required this.description,
    required this.indicator,
    required this.level,
  });

  final String id;
  final String name;
  final String englishName;
  final String description;

  /// 当前指标说明（由数据推导的结论）。
  final String indicator;
  final HealthLevel level;

  String get levelLabel => switch (level) {
    HealthLevel.good => '良好',
    HealthLevel.warning => '注意',
    HealthLevel.risk => '警示',
    HealthLevel.notAssessed => '待问卷',
  };
}

/// 健康度体检报告。
class HealthReport {
  const HealthReport({
    required this.dimensions,
    required this.overall,
    required this.score,
    required this.temperature,
  });

  final List<HealthDimension> dimensions;
  final HealthLevel overall;

  /// 已评估维度平均分（1-3）。
  final double score;

  /// 组织温度计（36.5°C 基准，体温隐喻）。
  final double temperature;

  int get goodCount =>
      dimensions.where((d) => d.level == HealthLevel.good).length;
  int get warningCount =>
      dimensions.where((d) => d.level == HealthLevel.warning).length;
  int get riskCount =>
      dimensions.where((d) => d.level == HealthLevel.risk).length;
  int get notAssessedCount =>
      dimensions.where((d) => d.level == HealthLevel.notAssessed).length;
}

/// 从组织数据推导健康度（指标与分级约定见 data/context/handbook/health.md）。
HealthReport computeHealthReport({
  required List<Retrospective> retrospectives,
  required List<ReportRelation> reportRelations,
  required List<Position> positions,
  required List<Member> members,
  required List<ChangeRecord> changeRecords,
}) {
  // 1. 方向：复盘结论沉淀率
  final retros = retrospectives;
  final conclusionRate = retros.isEmpty
      ? 0.0
      : retros.where((r) => r.conclusions.isNotEmpty).length / retros.length;
  final directionLevel = _rateLevel(conclusionRate);

  // 2. 领导力：最大管理幅度（单成员直属下属数）
  final spans = <String, Set<String>>{};
  for (final relation in reportRelations.where((r) => r.active)) {
    spans.putIfAbsent(relation.reportsToId, () => {}).add(relation.memberId);
  }
  var maxSpan = 0;
  for (final members in spans.values) {
    if (members.length > maxSpan) maxSpan = members.length;
  }
  final leadershipLevel = maxSpan <= 5
      ? HealthLevel.good
      : (maxSpan <= 8 ? HealthLevel.warning : HealthLevel.risk);

  // 3. 文化：复盘按时召开率
  final heldRate = retros.isEmpty
      ? 0.0
      : retros.where((r) => r.status == RetrospectiveStatus.held).length /
            retros.length;
  final cultureLevel = _rateLevel(heldRate);

  // 4. 责任：单点风险岗位数
  final singlePoints = positions
      .where((p) => p.isSinglePoint && p.status == PositionStatus.active)
      .length;
  final accountabilityLevel = singlePoints == 0
      ? HealthLevel.good
      : (singlePoints <= 2 ? HealthLevel.warning : HealthLevel.risk);

  // 5. 协调与控制：待审批变更滞留数
  final pendingCount = changeRecords
      .where((c) => c.approval == ApprovalStatus.pending)
      .length;
  final coordinationLevel = pendingCount == 0
      ? HealthLevel.good
      : (pendingCount <= 2 ? HealthLevel.warning : HealthLevel.risk);

  // 6. 能力：编制完整率（已占用/编制总数）
  final activePositions = positions
      .where((p) => p.status == PositionStatus.active)
      .toList();
  var filledSum = 0;
  var headcountSum = 0;
  for (final position in activePositions) {
    filledSum += position.filled;
    headcountSum += position.headcount;
  }
  final fillRate = headcountSum == 0 ? 0.0 : filledSum / headcountSum;
  final capabilityLevel = _rateLevel(fillRate);

  // 7. 激励：复盘参与覆盖率（参与人/在职成员）
  final activeMembers = members.where((m) => !m.isDeparted).toList();
  final participantIds = retros.expand((r) => r.participantIds).toSet();
  final coveredMembers = activeMembers
      .where((m) => participantIds.contains(m.id))
      .length;
  final coverage = activeMembers.isEmpty
      ? 0.0
      : coveredMembers / activeMembers.length;
  final motivationLevel = _rateLevel(coverage);

  // 8. 外部导向：无数据源，待问卷接入
  // 9. 创新与学习：变更活跃度
  final changeCount = changeRecords.length;
  final innovationLevel = changeCount >= 2
      ? HealthLevel.good
      : (changeCount >= 1 ? HealthLevel.warning : HealthLevel.risk);

  final dimensions = [
    HealthDimension(
      id: 'direction',
      name: '方向',
      englishName: 'Direction',
      description: '组织是否清楚往哪走、为什么',
      indicator: '复盘结论沉淀率 ${(conclusionRate * 100).round()}%',
      level: directionLevel,
    ),
    HealthDimension(
      id: 'leadership',
      name: '领导力',
      englishName: 'Leadership',
      description: '领导者是否担当、可信、有远见',
      indicator: '最大管理幅度 $maxSpan 人',
      level: leadershipLevel,
    ),
    HealthDimension(
      id: 'culture',
      name: '文化',
      englishName: 'Culture',
      description: '团队氛围、协作方式是否健康',
      indicator: '复盘按时召开率 ${(heldRate * 100).round()}%',
      level: cultureLevel,
    ),
    HealthDimension(
      id: 'accountability',
      name: '责任',
      englishName: 'Accountability',
      description: '职责是否清晰、是否有人兜底',
      indicator: '单点风险岗位 $singlePoints 个',
      level: accountabilityLevel,
    ),
    HealthDimension(
      id: 'coordination',
      name: '协调与控制',
      englishName: 'Coordination & Control',
      description: '跨部门协作与管控是否顺畅',
      indicator: '待审批变更 $pendingCount 笔',
      level: coordinationLevel,
    ),
    HealthDimension(
      id: 'capabilities',
      name: '能力',
      englishName: 'Capabilities',
      description: '岗位配置与人才能力是否匹配',
      indicator: '编制完整率 ${(fillRate * 100).round()}%',
      level: capabilityLevel,
    ),
    HealthDimension(
      id: 'motivation',
      name: '激励',
      englishName: 'Motivation',
      description: '成员是否被激发、有参与感',
      indicator: '复盘参与覆盖率 ${(coverage * 100).round()}%',
      level: motivationLevel,
    ),
    const HealthDimension(
      id: 'external',
      name: '外部导向',
      englishName: 'External Orientation',
      description: '是否感知外部环境与客户',
      indicator: '需问卷接入',
      level: HealthLevel.notAssessed,
    ),
    HealthDimension(
      id: 'innovation',
      name: '创新与学习',
      englishName: 'Innovation & Learning',
      description: '是否在反思、迭代、学习',
      indicator: '近期变更记录 $changeCount 笔',
      level: innovationLevel,
    ),
  ];

  final evaluated = dimensions
      .where((d) => d.level != HealthLevel.notAssessed)
      .toList();
  var scoreSum = 0.0;
  for (final dimension in evaluated) {
    scoreSum += switch (dimension.level) {
      HealthLevel.good => 3,
      HealthLevel.warning => 2,
      HealthLevel.risk => 1,
      HealthLevel.notAssessed => 0,
    };
  }
  final score = evaluated.isEmpty ? 0.0 : scoreSum / evaluated.length;
  final overall = score >= 2.5
      ? HealthLevel.good
      : (score >= 1.5 ? HealthLevel.warning : HealthLevel.risk);
  final temperature = 36.5 + (score - 2) * 0.3;

  return HealthReport(
    dimensions: dimensions,
    overall: overall,
    score: score,
    temperature: temperature,
  );
}

HealthLevel _rateLevel(double rate) => rate >= 0.8
    ? HealthLevel.good
    : (rate >= 0.5 ? HealthLevel.warning : HealthLevel.risk);
