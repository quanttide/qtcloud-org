import 'package:flutter/material.dart';

/// 应用导航骨架：宽屏左侧导航栏，窄屏底部导航栏。
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.pages});

  final List<Widget> pages;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _labels = ['首页', '架构', '成员', '复盘'];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: Text(_labels[0]),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.account_tree_outlined),
                  selectedIcon: const Icon(Icons.account_tree),
                  label: Text(_labels[1]),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.people_outline),
                  selectedIcon: const Icon(Icons.people),
                  label: Text(_labels[2]),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.assignment_outlined),
                  selectedIcon: const Icon(Icons.assignment),
                  label: Text(_labels[3]),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: widget.pages[_index]),
          ],
        ),
      );
    }
    return Scaffold(
      body: widget.pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '首页'),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            label: '架构',
          ),
          NavigationDestination(icon: Icon(Icons.people_outline), label: '成员'),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: '复盘',
          ),
        ],
      ),
    );
  }
}
