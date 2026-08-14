import 'models/change_record.dart';
import 'models/member/member.dart';
import 'models/org/department.dart';
import 'models/org/position.dart';
import 'models/org/report_relation.dart';
import 'models/retrospective/retrospective.dart';
import 'models/risk_item.dart';

/// 内存示例数据（原型阶段替代数据层；事实与风险推导逻辑在此集中）。
class SampleData {
  SampleData({
    required this.departments,
    required this.positions,
    required this.reportRelations,
    required this.members,
    required this.retrospectives,
    required this.changeRecords,
  });

  final List<Department> departments;
  final List<Position> positions;
  final List<ReportRelation> reportRelations;
  final List<Member> members;
  final List<Retrospective> retrospectives;
  final List<ChangeRecord> changeRecords;

  Department departmentById(String id) =>
      departments.firstWhere((d) => d.id == id);

  Position positionById(String id) => positions.firstWhere((p) => p.id == id);

  Member memberById(String id) => members.firstWhere((m) => m.id == id);

  /// 成员担任的岗位（含已离职成员的遗留岗位）。
  List<Position> positionsOf(Member member) =>
      positions.where((p) => member.positions.contains(p.id)).toList();

  /// 岗位当前任职成员（active）。
  List<Member> membersOfPosition(Position position) => members
      .where((m) => m.positions.contains(position.id) && !m.isDeparted)
      .toList();

  /// 待审批变更（首页「待审批变更」）。
  List<ChangeRecord> get pendingChanges =>
      changeRecords.where((c) => c.approval == ApprovalStatus.pending).toList();

  /// 风险聚合：岗位单人承担 / 岗位空缺 / 复盘组织者=单人。
  List<RiskItem> get risks {
    final items = <RiskItem>[];
    for (final position in positions.where(
      (p) => p.status == PositionStatus.active,
    )) {
      if (position.isVacant) {
        items.add(
          RiskItem(
            type: RiskType.vacancy,
            subject: '「${position.name}」岗位空缺',
            alternatives: _suggestionsFor(position),
          ),
        );
      } else if (position.isSinglePoint) {
        items.add(
          RiskItem(
            type: RiskType.singlePoint,
            subject: '「${position.name}」仅一人承担',
            alternatives: _suggestionsFor(position),
          ),
        );
      }
    }
    for (final retro in retrospectives.where(
      (r) => r.status == RetrospectiveStatus.scheduled,
    )) {
      final organizer = memberById(retro.organizerId);
      items.add(
        RiskItem(
          type: RiskType.organizerSingle,
          subject: '「${retro.scheduleDate} ${_retroTitle(retro)}」复盘组织者=单人',
          alternatives: members
              .where((m) => m.id != organizer.id && !m.isDeparted)
              .map((m) => m.name)
              .toList(),
        ),
      );
    }
    return items;
  }

  List<String> _suggestionsFor(Position position) =>
      members.where((m) => !m.isDeparted).map((m) => m.name).toList();

  String _retroTitle(Retrospective retro) => retro.id;
}

/// 全局示例数据。
final sampleData = SampleData(
  departments: const [
    Department(id: 'dept-gov', name: '治理部'),
    Department(id: 'dept-rd', name: '产品研发部'),
    Department(id: 'dept-ops', name: '运营部'),
  ],
  positions: const [
    Position(
      id: 'pos-founder',
      departmentId: 'dept-gov',
      name: '创始人',
      headcount: 1,
      filled: 1,
    ),
    Position(
      id: 'pos-product',
      departmentId: 'dept-rd',
      name: '产品负责人',
      headcount: 1,
      filled: 0,
    ),
    Position(
      id: 'pos-dev',
      departmentId: 'dept-rd',
      name: '研发工程师',
      headcount: 2,
      filled: 1,
    ),
    Position(
      id: 'pos-ops',
      departmentId: 'dept-ops',
      name: '运营专员',
      headcount: 1,
      filled: 1,
    ),
  ],
  members: const [
    Member(
      id: 'member-zhang',
      name: '张三',
      positions: ['pos-founder'],
      status: MemberStatus.active,
    ),
    Member(
      id: 'member-li',
      name: '李四',
      positions: ['pos-dev', 'pos-ops'],
      reportsToId: 'member-zhang',
    ),
    Member(
      id: 'member-wang',
      name: '王五',
      positions: ['pos-product'],
      reportsToId: 'member-zhang',
      status: MemberStatus.departed,
    ),
  ],
  reportRelations: const [
    ReportRelation(
      id: 'rel-1',
      memberId: 'member-zhang',
      positionId: 'pos-founder',
      reportsToId: 'org-main',
    ),
    ReportRelation(
      id: 'rel-2',
      memberId: 'member-li',
      positionId: 'pos-dev',
      reportsToId: 'member-zhang',
    ),
    ReportRelation(
      id: 'rel-3',
      memberId: 'member-li',
      positionId: 'pos-ops',
      reportsToId: 'member-zhang',
    ),
    ReportRelation(
      id: 'rel-4',
      memberId: 'member-wang',
      positionId: 'pos-product',
      reportsToId: 'member-zhang',
      active: false,
    ),
  ],
  retrospectives: const [
    Retrospective(
      id: 'retro-weekly',
      scheduleDate: '2026-08-20',
      organizerId: 'member-zhang',
      participantIds: ['member-li'],
      conclusions: ['复盘结论示例：本周例会机制运转正常'],
    ),
  ],
  changeRecords: const [
    ChangeRecord(
      id: 'change-001',
      authorId: 'member-zhang',
      timestamp: '2026-08-14T10:00:00+08:00',
      approval: ApprovalStatus.pending,
      summary: '新增研发工程师编制 1 名',
      changes: [
        Change(
          object: 'Position',
          field: 'headcount',
          oldValue: '2',
          newValue: '3',
        ),
      ],
    ),
    ChangeRecord(
      id: 'change-002',
      authorId: 'member-zhang',
      timestamp: '2026-08-13T15:00:00+08:00',
      approval: ApprovalStatus.approved,
      commitId: 'a1b2c3d',
      summary: '王五离职（人事云事件落库）',
      changes: [
        Change(
          object: 'Member',
          field: 'status',
          oldValue: 'active',
          newValue: 'departed',
        ),
      ],
    ),
  ],
);
