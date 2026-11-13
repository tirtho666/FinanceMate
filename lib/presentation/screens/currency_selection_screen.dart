import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/currencies.dart';
import '../providers/home_provider.dart';
import '../providers/user_provider.dart';

class CurrencySelectionScreen extends StatefulWidget {
  const CurrencySelectionScreen({super.key});

  @override
  State<CurrencySelectionScreen> createState() =>
      _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen> {
  late String _selectedCode;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final home = context.read<HomeProvider>();
    _selectedCode = home.profile.currency;
  }

  List<CurrencyInfo> get _filteredCurrencies {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return Currencies.primary;
    return Currencies.all.where((c) {
      return c.code.toLowerCase().contains(query) ||
          c.name.toLowerCase().contains(query) ||
          c.longName.toLowerCase().contains(query);
    }).toList();
  }

  bool get _showMoreHint =>
      _searchQuery.isEmpty && Currencies.all.length > Currencies.primary.length;

  Future<void> _save() async {
    final user = context.read<UserProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await user.updateCurrency(_selectedCode);
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (user.successMessage ?? 'Currency saved!')
                : (user.errorMessage ?? 'Could not save currency.'),
          ),
          backgroundColor: success ? AppPalette.income : AppPalette.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    if (success) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final user = context.watch<UserProvider>();
    final home = context.watch<HomeProvider>();
    final profile = home.profile;
    final displayName = user.displayNameOr(profile);
    final filtered = _filteredCurrencies;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new, color: colors.primary),
        ),
        title: Text(
          'Select Currency',
          style: textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary.withValues(alpha: 0.08),
                        ),
                        child: Icon(
                          Icons.person,
                          color: colors.primary.withValues(alpha: 0.5),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayName,
                        style: textTheme.titleLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...filtered.map(
                    (currency) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CurrencyTile(
                        currency: currency,
                        selected: _selectedCode == currency.code,
                        onTap: () => setState(() => _selectedCode = currency.code),
                      ),
                    ),
                  ),
                  if (_showMoreHint) ...[
                    const SizedBox(height: 2),
                    _SearchHintField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ],
                  const SizedBox(height: 28),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: user.isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppPalette.income,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppPalette.income.withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: user.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Selection'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({
    required this.currency,
    required this.selected,
    required this.onTap,
  });

  final CurrencyInfo currency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppPalette.income.withValues(alpha: 0.7)
                  : colors.primary.withValues(alpha: 0.08),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currency.flagColor.withValues(alpha: 0.15),
                ),
                child: Icon(
                  currency.flagIcon,
                  color: currency.flagColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '${currency.code} - ${currency.longName}',
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: selected
                    ? Container(
                        key: const ValueKey('check'),
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppPalette.income,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        ),
                      )
                    : Container(
                        key: const ValueKey('radio'),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchHintField extends StatelessWidget {
  const _SearchHintField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextField(
        onChanged: onChanged,
        style: textTheme.titleSmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'More currencies...',
          hintStyle: textTheme.bodyMedium?.copyWith(
            color: colors.primary.withValues(alpha: 0.55),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: colors.primary.withValues(alpha: 0.55),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colors.primary.withValues(alpha: 0.08),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
