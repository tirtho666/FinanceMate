import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../domain/entities/finance_transaction.dart';
import '../providers/transaction_list_provider.dart';
import '../widgets/category_picker_bottom_sheet.dart';
import '../widgets/category_style.dart';
import '../widgets/transaction_tile.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final provider = context.watch<TransactionListProvider>();

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'All Transactions',
                      style: textTheme.headlineSmall,
                    ),
                  ),
                  if (provider.hasCategoryFilter ||
                      provider.timeFilter !=
                          TransactionTimeFilter.thisMonth)
                    IconButton(
                      tooltip: 'Clear filters',
                      onPressed: provider.clearFilters,
                      icon: Icon(
                        Icons.filter_alt_off_outlined,
                        color: colors.expense,
                      ),
                    )
                  else
                    IconButton(
                      tooltip: 'Filter',
                      onPressed: () {},
                      icon: Icon(Icons.tune, color: colors.primary),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: SizedBox(
                height: 44,
                child: _FilterBar(
                  timeFilter: provider.timeFilter,
                  categoryFilter: provider.categoryFilter,
                  onTimeChanged: provider.setTimeFilter,
                  onCategoryPressed: () => _openCategoryPicker(context),
                ),
              ),
            ),
            if (provider.hasCategoryFilter)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _ActiveCategoryChip(
                  category: provider.categoryFilter!,
                  onDismiss: provider.clearCategoryFilter,
                ),
              ),
            Expanded(
              child: _Body(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCategoryPicker(BuildContext context) async {
    final provider = context.read<TransactionListProvider>();
    final selected = await CategoryPickerBottomSheet.show(
      context,
      selectedCategory: provider.categoryFilter,
    );
    if (!context.mounted) return;
    provider.setCategoryFilter(selected);
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.timeFilter,
    required this.categoryFilter,
    required this.onTimeChanged,
    required this.onCategoryPressed,
  });

  final TransactionTimeFilter timeFilter;
  final String? categoryFilter;
  final ValueChanged<TransactionTimeFilter> onTimeChanged;
  final VoidCallback onCategoryPressed;

  @override
  Widget build(BuildContext context) {
    final items = <_FilterChipSpec>[
      // Notun jog kora "All" button, jeta shobar baa-pashe thakbe
      _FilterChipSpec(
        label: 'All',
        isSelected: timeFilter == TransactionTimeFilter.all,
        onTap: () => onTimeChanged(TransactionTimeFilter.all),
      ),
      _FilterChipSpec(
        label: 'This Month',
        isSelected: timeFilter == TransactionTimeFilter.thisMonth,
        onTap: () => onTimeChanged(TransactionTimeFilter.thisMonth),
      ),
      _FilterChipSpec(
        label: 'Last Month',
        isSelected: timeFilter == TransactionTimeFilter.lastMonth,
        onTap: () => onTimeChanged(TransactionTimeFilter.lastMonth),
      ),
      _FilterChipSpec(
        label: 'Category',
        isSelected: categoryFilter != null,
        trailing: categoryFilter != null
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 6),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppPalette.onPrimary.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              )
            : const SizedBox.shrink(),
        onTap: onCategoryPressed,
      ),
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _FilterChip(
          label: item.label,
          selected: item.isSelected,
          trailing: item.trailing,
          onTap: item.onTap,
        );
      },
    );
  }
}

@immutable
class _FilterChipSpec {
  const _FilterChipSpec({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool isSelected;
  final Widget? trailing;
  final VoidCallback onTap;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    this.trailing,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: selected ? colors.primary : AppPalette.onPrimary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? colors.primary
                  : colors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.textTheme.labelMedium?.copyWith(
                  color: selected ? colors.onPrimary : colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveCategoryChip extends StatelessWidget {
  const _ActiveCategoryChip({
    required this.category,
    required this.onDismiss,
  });

  final String category;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.forName(category);
    final textTheme = context.textTheme;
    return Row(
      children: [
        Container(
          height: 36,
          padding: const EdgeInsetsDirectional.only(start: 6, end: 4),
          decoration: BoxDecoration(
            color: style.background.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: style.background.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: style.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.foreground, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: textTheme.labelMedium?.copyWith(
                  color: context.appColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: context.appColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppPalette.onPrimary,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionListProvider>();
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppPalette.primary),
      );
    }
    if (provider.errorMessage != null) {
      return _ErrorState(message: provider.errorMessage!);
    }
    if (provider.isEmpty) {
      return const _EmptyState();
    }
    return _TransactionList(
      transactions: provider.filteredTransactions,
      currency: provider.currency,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 72,
              color: colors.expense.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load transactions',
              style: textTheme.titleMedium?.copyWith(color: colors.expense),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onBackground.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.find_in_page_outlined,
              size: 88,
              color: colors.primary.withValues(alpha: 0.28),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: textTheme.titleMedium?.copyWith(
                color: colors.primary.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting the filters, or add your first transaction.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.primary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.transactions, required this.currency});

  final List<FinanceTransaction> transactions;
  final String currency;

  Future<void> _confirmDelete(BuildContext context, FinanceTransaction transaction) async {
    final provider = context.read<TransactionListProvider>();
    final colors = context.appColors;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Delete Transaction?',
          style: context.textTheme.titleMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will permanently delete this transaction and update your total balance. Are you sure?',
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.primary.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.primary.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) return;

    // Capture the messenger before awaiting so the result can be reported
    // safely. Success is only shown once the backend *and* the local cache have
    // both permanently dropped the row; otherwise the exact error is surfaced in
    // red and the list has already been rolled back.
    final messenger = ScaffoldMessenger.of(context);
    final error = await provider.deleteTransaction(transaction);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error ?? 'Transaction deleted successfully'),
          backgroundColor:
              error == null ? AppPalette.primary : AppPalette.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return GestureDetector(
          onLongPress: () => _confirmDelete(context, transaction),
          child: TransactionTile(
            transaction: transaction,
            currency: currency,
          ),
        );
      },
    );
  }
}