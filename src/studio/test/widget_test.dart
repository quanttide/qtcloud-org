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

  testWidgets('健康度总览展示组织温度计与 OHI 九维度', (tester) async {
    await tester.pumpWidget(const QtcloudOrgStudioApp());

    await tester.tap(find.text('健康度'));
    await tester.pumpAndSettle();

    expect(find.text('组织健康度'), findsOneWidget);
    expect(find.text('组织温度计'), findsOneWidget);
    expect(find.text('方向 Direction'), findsOneWidget);

    await tester.drag(find.text('组织温度计'), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.text('外部导向 External Orientation'), findsOneWidget);
    expect(find.text('待问卷'), findsOneWidget);
  });

  testWidgets('健康度页查看复盘记录与结论', (tester) async {
    await tester.pumpWidget(const QtcloudOrgStudioApp());

    await tester.tap(find.text('健康度'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复盘记录'));
    await tester.pumpAndSettle();

    expect(find.text('2026-08-20'), findsOneWidget);
    await tester.tap(find.text('2026-08-20'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('复盘 · 2026-08-20'), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('结论沉淀'), findsOneWidget);
    expect(find.textContaining('复盘结论示例'), findsOneWidget);
  });

  testWidgets('复盘状态流转：标记已召开后待召开消失', (tester) async {
    await tester.pumpWidget(const QtcloudOrgStudioApp());

    await tester.tap(find.text('健康度'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复盘记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026-08-20'));
    await tester.pumpAndSettle();

    expect(find.text('待召开'), findsWidgets);
    await tester.tap(find.text('标记已召开'));
    await tester.pumpAndSettle();

    expect(find.text('已召开'), findsOneWidget);
    expect(find.text('待召开'), findsNothing);
    expect(find.text('无单点风险'), findsOneWidget);
  });
}
