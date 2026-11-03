import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_org_studio/main.dart';

/// 架构编辑器：增、改、移、删（部门与岗位），写操作落 ChangeRecord 留痕。
void main() {
  Future<void> openStructure(WidgetTester tester) async {
    await tester.pumpWidget(const QtcloudOrgStudioApp());
    await tester.tap(find.text('架构'));
    await tester.pumpAndSettle();
  }

  Future<void> createDepartment(WidgetTester tester, String name) async {
    await tester.tap(find.byTooltip('新增部门'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), name);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
  }

  Future<void> createPosition(
    WidgetTester tester, {
    required String name,
    required String headcount,
  }) async {
    await tester.tap(find.byTooltip('新增岗位'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), name);
    await tester.enterText(find.byType(TextFormField).at(1), headcount);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
  }

  testWidgets('新增部门与岗位进入架构树', (tester) async {
    await openStructure(tester);

    await createDepartment(tester, '战略投资部');
    expect(find.text('战略投资部'), findsWidgets);
    expect(find.byTooltip('部门操作'), findsOneWidget);

    await createPosition(tester, name: '投资经理', headcount: '3');
    expect(find.text('投资经理'), findsWidgets);
    expect(find.text('0/3'), findsOneWidget);
    expect(find.byTooltip('岗位操作'), findsOneWidget);
  });

  testWidgets('重命名部门：架构树更新并落变更记录', (tester) async {
    await openStructure(tester);
    await createDepartment(tester, '部门甲');

    await tester.tap(find.byTooltip('部门操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重命名部门'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '部门乙');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(find.text('部门乙'), findsWidgets);
    expect(find.text('部门甲'), findsNothing);

    await tester.tap(find.text('创始人'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('部门「部门甲」重命名为「部门乙」'),
      findsOneWidget,
    );
  });

  testWidgets('编辑岗位：改编制立即生效并留痕', (tester) async {
    await openStructure(tester);

    await tester.tap(find.text('研发工程师'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('岗位操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑岗位'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '5');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('编制：5'), findsOneWidget);
  });

  testWidgets('删除有岗位的部门被拦截', (tester) async {
    await openStructure(tester);
    await createDepartment(tester, '部门丙');
    await createPosition(tester, name: '丙岗位', headcount: '1');

    // 等提示条自动收起，否则会遮挡架构树底部的点击
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // 新部门排在树末尾（列表惰性构建），先滚到可见
    await tester.scrollUntilVisible(
      find.text('部门丙'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    // 岗位创建后选中的是岗位，需回到部门（收起再展开即选中）
    await tester.tap(find.text('部门丙'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('部门丙'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('部门丙'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('部门操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除部门'));
    await tester.pumpAndSettle();

    expect(find.textContaining('先移动或删除岗位'), findsWidgets);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('删除空部门生效并从架构树移除', (tester) async {
    await openStructure(tester);
    await createDepartment(tester, '部门丁');

    await tester.tap(find.byTooltip('部门操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除部门'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(find.text('部门丁'), findsNothing);
    expect(find.byTooltip('部门操作'), findsNothing);
    expect(find.textContaining('已删除部门「部门丁」'), findsOneWidget);
  });

  testWidgets('删除挂在成员名下的岗位被拦截', (tester) async {
    await openStructure(tester);

    await tester.tap(find.text('创始人'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('岗位操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除岗位'));
    await tester.pumpAndSettle();

    expect(find.textContaining('仍挂在成员名下'), findsWidgets);
  });
}
