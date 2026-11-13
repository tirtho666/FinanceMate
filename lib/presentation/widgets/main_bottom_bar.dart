import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../screens/main_tab.dart';

class MainBottomBar extends StatelessWidget {
  const MainBottomBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final MainTab currentTab;
  final ValueChanged<MainTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      color: AppPalette.onPrimary,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                  selected: currentTab == MainTab.home,
                  onTap: () => onTabSelected(MainTab.home),
                ),
              ),
              _AddButton(
                selected: currentTab == MainTab.add,
                onTap: () => onTabSelected(MainTab.add),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long_rounded,
                  label: 'All',
                  selected: currentTab == MainTab.all,
                  onTap: () => onTabSelected(MainTab.all),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = selected ? colors.primary : const Color(0xFF9AA6B2);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? selectedIcon : icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: FloatingActionButton(
              heroTag: 'main-add-fab',
              onPressed: onTap,
              elevation: selected ? 4 : 2,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 30),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Add',
            style: context.textTheme.labelSmall?.copyWith(
              color: selected ? colors.primary : const Color(0xFF9AA6B2),
            ),
          ),
        ],
      ),
    );
  }
}
