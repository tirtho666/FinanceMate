import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/finance_transaction.dart';
import 'category_style.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.currency,
  });

  final FinanceTransaction transaction;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.forName(transaction.category);
    final isIncome = transaction.type == TransactionType.income;
    final amountColor =
        isIncome ? context.appColors.income : context.appColors.expense;

    // Note ase ki na ta check kora hocche
    final hasNote = transaction.note != null && transaction.note!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: style.background,
            child: Icon(style.icon, color: style.foreground, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category, 
                  style: context.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.date(transaction.date),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                // Jodi note thake, tahole date er niche dekhabe
                if (hasNote) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.note!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Formatters.signedCurrency(
              currency,
              transaction.amount,
              isIncome: isIncome,
            ),
            style: context.textTheme.titleSmall?.copyWith(color: amountColor),
          ),
        ],
      ),
    );
  }
}