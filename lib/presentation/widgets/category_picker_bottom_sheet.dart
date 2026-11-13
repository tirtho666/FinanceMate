import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'category_style.dart';

class CategoryPickerBottomSheet extends StatelessWidget {
  const CategoryPickerBottomSheet({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final String? selectedCategory;
  final ValueChanged<String> onCategorySelected;

  static Future<String?> show(
    BuildContext context, {
    String? selectedCategory,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryPickerBottomSheet(
        selectedCategory: selectedCategory,
        onCategorySelected: (category) {
          Navigator.of(context).pop(category);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Error fix kora hoyeche ekhane
    final textTheme = Theme.of(context).textTheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppPalette.onPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Text(
                  'Select Category',
                  style: textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: CategoryStyle.allCategories.length,
                  itemBuilder: (context, index) {
                    final category = CategoryStyle.allCategories[index];
                    final style = CategoryStyle.forName(category);
                    final isSelected =
                        selectedCategory?.trim().toLowerCase() ==
                            category.trim().toLowerCase();
                    return _CategoryGridItem(
                      category: category,
                      style: style,
                      isSelected: isSelected,
                      onTap: () => onCategorySelected(category),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryGridItem extends StatelessWidget {
  const _CategoryGridItem({
    required this.category,
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  final String category;
  final CategoryStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Error fix kora hoyeche ekhane
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: style.background,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: style.background.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                  border: isSelected
                      ? Border.all(
                          color: AppPalette.primary.withValues(alpha: 0.2),
                          width: 2,
                        )
                      : null,
                ),
                child: Icon(
                  style.icon,
                  color: style.foreground,
                  size: 30,
                ),
              ),
              if (isSelected)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppPalette.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppPalette.onPrimary,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              category,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? AppPalette.primary
                    : AppPalette.onBackground.withValues(alpha: 0.75),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}