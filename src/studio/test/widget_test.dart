import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_org_studio/main.dart';

void main() {
  testWidgets('app 启动渲染首页聚合（待审批变更）', (tester) async {
    await tester.pumpWidget(const QtcloudOrgStudioApp());

    expect(find.text('量潮组织云'), findsOneWidget);
    expect(find.text('待审批变更'), findsOneWidget);
    expect(find.text('新增研发工程师编制 1 名'), findsOneWidget);
  });

  testWidgets('首页聚合展示风险清单与岗位空缺', (tester) async {
    await tester.pumpWidget(const QtcloudOrgStudioApp());

    expect(find.text('风险清单'), findsOneWidget);
    expect(find.textContaining('仅一人承担'), findsWidgets);
    expect(find.textContaining('岗位空缺'), findsWidgets);
  });

  testWidgets('导航到架构页并选择岗位查看详情', (tester) async {
    await tester.pumpWidget(const QtcloudOrgStudioApp());

    await tester.tap(find.text('架构'));
    await tester.pumpAndSettle();

    expect(find.text('组织架构'), findsOneWidget);
    await tester.tap(find.text('创始人'));
    await tester.pumpAndSettle();
    expect(find.text('汇报链路'), findsOneWidget);
    expect(find.text('版本历史'), findsOneWidget);
    expect(find.text('任职成员'), findsOneWidget);
  });

  testWidgets('导航到成员页并查看成员变动影响', (tester) async {
    await tester.pumpWidget(const QtcloudOrgStudioApp());

    await tester.tap(find.text('成员'));
    await tester.pumpAndSettle();

    expect(find.text('成员与职责'), findsOneWidget);
    await tester.tap(find.text('王五'));
    await tester.pumpAndSettle();

    expect(find.text('成员变动影响'), findsOneWidget);
    expect(find.textContaining('产品负责人'), findsWidgets);
  });

  testWidgets('导航到复盘页并查看结论', (tester) async {
    await tester.pumpWidget(const QtcloudOrgStudioApp());

    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();

    expect(find.text('2026-08-20'), findsOneWidget);
    await tester.tap(find.text('2026-08-20'));
    await tester.pumpAndSettle();

    expect(find.text('结论沉淀'), findsOneWidget);
    expect(find.textContaining('复盘结论示例'), findsOneWidget);
  });
}
