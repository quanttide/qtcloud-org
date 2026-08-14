import 'package:flutter/material.dart';

import 'screens/health/health_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/members/members_screen.dart';
import 'screens/org_structure/org_structure_screen.dart';
import 'widgets/navigation/app_shell.dart';

void main() {
  runApp(const QtcloudOrgStudioApp());
}

class QtcloudOrgStudioApp extends StatelessWidget {
  const QtcloudOrgStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '量潮组织云',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AppShell(
        pages: [
          HomeScreen(),
          OrgStructureScreen(),
          MembersScreen(),
          HealthScreen(),
        ],
      ),
    );
  }
}
