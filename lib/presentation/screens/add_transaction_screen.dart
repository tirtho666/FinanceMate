import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/currencies.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/finance_transaction.dart';
import '../providers/home_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/category_picker_bottom_sheet.dart';
import '../widgets/category_style.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final FocusNode _amountFocusNode;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TransactionProvider>();
    _amountController = TextEditingController(
      text: provider.amount > 0 ? provider.amount.toStringAsFixed(0) : '',
    );
    _noteController = TextEditingController(text: provider.note);
    _amountFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionProvider>().reset();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final provider = context.read<TransactionProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: provider.isIncome ? AppPalette.income : AppPalette.expense,
              onPrimary: AppPalette.onPrimary,
              surface: AppPalette.onPrimary,
              onSurface: AppPalette.onBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      provider.setDate(picked);
    }
  }

  Future<void> _openCategoryPicker() async {
    final provider = context.read<TransactionProvider>();
    final selected = await CategoryPickerBottomSheet.show(
      context,
      selectedCategory: provider.category,
    );
    if (selected != null && mounted) {
      provider.setCategory(selected);
    }
  }

  Future<void> _submit() async {
    final provider = context.read<TransactionProvider>();
    _amountFocusNode.unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.submit();
    
    if (!mounted) return;
    
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Transaction saved successfully!'
                : (provider.errorMessage ?? 'Could not save transaction.'),
          ),
          backgroundColor: success ? AppPalette.income : AppPalette.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      
    if (success) {
      // Transaction save howar sathe sathe text box gulo 100% faka kore dewa hocche
      _amountController.clear();
      _noteController.clear();
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final home = context.watch<HomeProvider>();
    final currencyInfo = Currencies.forCode(home.profile.currency);
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final accentColor = provider.isIncome ? colors.income : colors.expense;

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: Icon(Icons.arrow_back_ios_new, color: colors.primary),
                  ),
                  Expanded(
                    child: Text(
                      'Add Transaction',
                      style: textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _TypeToggle(
                      label: 'Expense',
                      selected: provider.type == TransactionType.expense,
                      selectedColor: colors.expense,
                      onTap: () => provider.setType(TransactionType.expense),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeToggle(
                      label: 'Income',
                      selected: provider.type == TransactionType.income,
                      selectedColor: colors.income,
                      onTap: () => provider.setType(TransactionType.income),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  Text('1. Amount', style: textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (value) {
                      provider.setAmountFromString(value);
                    },
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(
                        currencyInfo.flagIcon,
                        color: accentColor,
                      ),
                      prefixText: '${currencyInfo.symbol} ',
                      prefixStyle: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('2. Category', style: textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _CategoryField(
                    category: provider.category,
                    accentColor: accentColor,
                    onTap: _openCategoryPicker,
                  ),
                  const SizedBox(height: 16),
                  Text('3. Date', style: textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _DateField(
                    date: provider.date,
                    accentColor: accentColor,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),
                  Text('4. Note', style: textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    onChanged: provider.setNote,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Add a note (optional)',
                      prefixIcon: Icon(Icons.edit_note_outlined),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (provider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppPalette.expense.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppPalette.expense,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                provider.errorMessage!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppPalette.expense,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: provider.canSubmit ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: accentColor,
                        foregroundColor: AppPalette.onPrimary,
                        disabledBackgroundColor: accentColor.withValues(alpha: 0.4),
                        disabledForegroundColor:
                            AppPalette.onPrimary.withValues(alpha: 0.7),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: provider.isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppPalette.onPrimary,
                                ),
                              ),
                            )
                          : const Text('Save Transaction'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Nicher baki sob _TypeToggle, _CategoryField, _DateField aager motoi thakbe
class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? selectedColor : AppPalette.onPrimary,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? selectedColor
                  : context.appColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            style: context.textTheme.titleSmall?.copyWith(
              color: selected ? AppPalette.onPrimary : context.appColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.category,
    required this.accentColor,
    required this.onTap,
  });

  final String? category;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final hasCategory = category != null && category!.trim().isNotEmpty;
    final style = hasCategory ? CategoryStyle.forName(category!) : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: 'Select Category',
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
            prefixIcon: hasCategory
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: style!.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            style.icon,
                            color: style.foreground,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  )
                : const Icon(Icons.category_outlined),
            suffixIcon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: accentColor,
              size: 28,
            ),
          ),
          child: Text(
            hasCategory ? category! : 'Select Category',
            style: hasCategory
                ? textTheme.bodyMedium?.copyWith(
                    color: AppPalette.onBackground,
                    fontWeight: FontWeight.w600,
                  )
                : textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.date,
    required this.accentColor,
    required this.onTap,
  });

  final DateTime date;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.calendar_today_outlined, color: accentColor),
            suffixIcon: Icon(
              Icons.keyboard_arrow_right_rounded,
              color: accentColor,
              size: 28,
            ),
          ),
          child: Text(
            Formatters.date(date),
            style: textTheme.bodyMedium?.copyWith(
              color: AppPalette.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}