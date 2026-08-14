/// 通用变更记录——所有写操作的统一表达，审批留痕与版本历史由此承载。
enum ApprovalStatus { pending, approved, rejected, auto }

/// 单条字段级变更内容。
class Change {
  const Change({
    required this.object,
    required this.field,
    this.oldValue,
    this.newValue,
  });

  final String object;
  final String field;
  final String? oldValue;
  final String? newValue;
}

class ChangeRecord {
  const ChangeRecord({
    required this.id,
    required this.authorId,
    required this.timestamp,
    this.approval = ApprovalStatus.pending,
    this.commitId,
    required this.summary,
    this.changes = const [],
  });

  final String id;
  final String authorId;
  final String timestamp;
  final ApprovalStatus approval;

  /// 数据层 git 提交 id（原型阶段为 null）。
  final String? commitId;

  /// 变更说明（为什么改）。
  final String summary;
  final List<Change> changes;
}
