import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/home_provider.dart';
import '../widgets/transaction_tile.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final profile = home.profile;
    final currency = profile.currency;

    return ColoredBox(
      color: colors.background,
      child: Column(
        children: [
          Material(
            color: AppPalette.primary,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Finance Overview',
                        style: textTheme.titleLarge?.copyWith(
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Profile & Settings',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.account_circle_outlined,
                        color: colors.onPrimary,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: home.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    children: [
                      _OverviewCard(profile: profile, currency: currency),
                      const SizedBox(height: 28),
                      Text(
                        'Recent Transactions',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (home.hasTransactions)
                        ...home.recentTransactions.map(
                          (transaction) => TransactionTile(
                            transaction: transaction,
                            currency: currency,
                          ),
                        )
                      else
                        _EmptyTransactions(onAddPressed: onAddPressed),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.profile, required this.currency});

  final UserProfile profile;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    // Balance-er absolute value (positive value) ber kora hocche
    final absBalance = profile.balance.abs();
    
    // Balance onujayi sign set kora hocche
    String sign = '';
    if (profile.balance > 0) {
      sign = '+ ';
    } else if (profile.balance < 0) {
      sign = '- ';
    }

    // Sign ebong currency eksathe format kora hocche
    final displayBalance = '$sign${Formatters.currency(currency, absBalance)}';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFF082E4A),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Text(
                'Current Balance:',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayBalance, // Update kora formatted balance ekhane bosiye dewa holo
                style: textTheme.displaySmall?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryChip(
                label: 'Total Income',
                value: Formatters.currency(currency, profile.totalIncome),
                background: const Color(0xFFE7F6F3),
                foreground: colors.income,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryChip(
                label: 'Total Expense',
                value: Formatters.currency(currency, profile.totalExpense),
                background: const Color(0xFFFDECEC),
                foreground: colors.expense,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(color: foreground),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 96,
            color: colors.primary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet.\nClick ‘+’ to add your first!',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAddPressed,
            child: const Text('Add transaction'),
          ),
        ],
      ),
    );
  }
}