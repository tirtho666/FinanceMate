import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/main_bottom_bar.dart';
import 'add_transaction_screen.dart';
import 'all_transactions_screen.dart';
import 'home_screen.dart';
import 'main_tab.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  MainTab _currentTab = MainTab.home;
  MainTab _lastContentTab = MainTab.home;

  void _onTabSelected(MainTab tab) {
    setState(() {
      if (tab != MainTab.add) {
        _lastContentTab = tab;
      }
      _currentTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: IndexedStack(
        index: _currentTab.index,
        children: [
          HomeScreen(onAddPressed: () => _onTabSelected(MainTab.add)),
          AddTransactionScreen(
            onBack: () => _onTabSelected(_lastContentTab),
          ),
          const AllTransactionsScreen(),
        ],
      ),
      bottomNavigationBar: MainBottomBar(
        currentTab: _currentTab,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
