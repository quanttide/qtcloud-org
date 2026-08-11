/// 组织治理数据模型（手写版，无 freezed）。
///
/// 自 qtadmin 迁移，供 qtcloud-org 产品线恢复时参考。
/// 契约对齐 `examples/org.json`。

enum InstitutionStatus { normal, warning, overdue }

enum RepPerformanceTier { green, yellow, red }

InstitutionStatus _institutionStatusFromJson(Object? value) =>
    InstitutionStatus.values.byName(value as String);

RepPerformanceTier _tierFromJson(Object? value) =>
    RepPerformanceTier.values.byName(value as String);

class OrgInstitution {
  final String id;
  final String name;
  final String parentId;
  final int level;
  final InstitutionStatus status;
  final String? lastMeetingDate;
  final String? nextMeetingDate;
  final String expectedFrequency;
  final List<String> memberIds;
  final int pendingProposalCount;

  const OrgInstitution({
    required this.id,
    required this.name,
    this.parentId = '',
    this.level = 0,
    required this.status,
    this.lastMeetingDate,
    this.nextMeetingDate,
    this.expectedFrequency = '',
    this.memberIds = const [],
    this.pendingProposalCount = 0,
  });

  factory OrgInstitution.fromJson(Map<String, dynamic> json) => OrgInstitution(
    id: json['id'] as String,
    name: json['name'] as String,
    parentId: (json['parentId'] as String?) ?? '',
    level: (json['level'] as int?) ?? 0,
    status: _institutionStatusFromJson(json['status']),
    lastMeetingDate: json['lastMeetingDate'] as String?,
    nextMeetingDate: json['nextMeetingDate'] as String?,
    expectedFrequency: (json['expectedFrequency'] as String?) ?? '',
    memberIds:
        (json['memberIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    pendingProposalCount: (json['pendingProposalCount'] as int?) ?? 0,
  );
}

class OrgMeeting {
  final String id;
  final String institutionId;
  final String date;
  final String title;
  final List<String> agendaItems;
  final int attendeeCount;
  final int totalMemberCount;

  const OrgMeeting({
    required this.id,
    required this.institutionId,
    required this.date,
    required this.title,
    this.agendaItems = const [],
    this.attendeeCount = 0,
    this.totalMemberCount = 0,
  });

  factory OrgMeeting.fromJson(Map<String, dynamic> json) => OrgMeeting(
    id: json['id'] as String,
    institutionId: json['institutionId'] as String,
    date: json['date'] as String,
    title: json['title'] as String,
    agendaItems:
        (json['agendaItems'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    attendeeCount: (json['attendeeCount'] as int?) ?? 0,
    totalMemberCount: (json['totalMemberCount'] as int?) ?? 0,
  );
}

class OrgRepresentative {
  final String id;
  final String name;
  final List<String> institutionIds;
  final String rank;
  final String term;
  final double attendanceRate;
  final int proposalCount;
  final double voteRate;
  final int objectionCount;
  final RepPerformanceTier tier;
  final List<OrgMeeting> recentVotes;

  const OrgRepresentative({
    required this.id,
    required this.name,
    required this.institutionIds,
    required this.rank,
    this.term = '',
    this.attendanceRate = 0.0,
    this.proposalCount = 0,
    this.voteRate = 0.0,
    this.objectionCount = 0,
    required this.tier,
    this.recentVotes = const [],
  });

  factory OrgRepresentative.fromJson(Map<String, dynamic> json) =>
      OrgRepresentative(
        id: json['id'] as String,
        name: json['name'] as String,
        institutionIds: (json['institutionIds'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        rank: json['rank'] as String,
        term: (json['term'] as String?) ?? '',
        attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0.0,
        proposalCount: (json['proposalCount'] as int?) ?? 0,
        voteRate: (json['voteRate'] as num?)?.toDouble() ?? 0.0,
        objectionCount: (json['objectionCount'] as int?) ?? 0,
        tier: _tierFromJson(json['tier']),
        recentVotes:
            (json['recentVotes'] as List<dynamic>?)
                ?.map((e) => OrgMeeting.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class OrgRank {
  final String name;
  final bool isManagement;
  final int headCount;

  const OrgRank({
    required this.name,
    this.isManagement = false,
    this.headCount = 0,
  });

  factory OrgRank.fromJson(Map<String, dynamic> json) => OrgRank(
    name: json['name'] as String,
    isManagement: (json['isManagement'] as bool?) ?? false,
    headCount: (json['headCount'] as int?) ?? 0,
  );
}

class OrgPromotion {
  final String id;
  final String personName;
  final String fromRank;
  final String toRank;
  final String date;
  final bool isCrossTrack;

  const OrgPromotion({
    required this.id,
    required this.personName,
    required this.fromRank,
    required this.toRank,
    required this.date,
    this.isCrossTrack = false,
  });

  factory OrgPromotion.fromJson(Map<String, dynamic> json) => OrgPromotion(
    id: json['id'] as String,
    personName: json['personName'] as String,
    fromRank: json['fromRank'] as String,
    toRank: json['toRank'] as String,
    date: json['date'] as String,
    isCrossTrack: (json['isCrossTrack'] as bool?) ?? false,
  );
}

class OrgDashboard {
  final List<OrgInstitution> institutions;
  final List<OrgRepresentative> representatives;
  final List<OrgRank> ranks;
  final List<OrgPromotion> promotions;

  const OrgDashboard({
    required this.institutions,
    required this.representatives,
    required this.ranks,
    required this.promotions,
  });

  factory OrgDashboard.fromJson(Map<String, dynamic> json) => OrgDashboard(
    institutions: (json['institutions'] as List<dynamic>)
        .map((e) => OrgInstitution.fromJson(e as Map<String, dynamic>))
        .toList(),
    representatives: (json['representatives'] as List<dynamic>)
        .map((e) => OrgRepresentative.fromJson(e as Map<String, dynamic>))
        .toList(),
    ranks: (json['ranks'] as List<dynamic>)
        .map((e) => OrgRank.fromJson(e as Map<String, dynamic>))
        .toList(),
    promotions: (json['promotions'] as List<dynamic>)
        .map((e) => OrgPromotion.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
