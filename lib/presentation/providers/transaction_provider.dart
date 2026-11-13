import 'package:flutter/foundation.dart';

import '../../domain/entities/finance_transaction.dart';
import '../../domain/failures/data_failure.dart';
import '../../domain/usecases/add_transaction_with_user_update.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider({
    required this.addTransactionUseCase,
  });

  final AddTransactionWithUserUpdate addTransactionUseCase;

  TransactionType _type = TransactionType.expense;
  double _amount = 0;
  String? _category;
  DateTime _date = DateTime.now();
  String _note = '';

  bool _isSubmitting = false;
  String? _errorMessage;

  TransactionType get type => _type;
  double get amount => _amount;
  String? get category => _category;
  DateTime get date => _date;
  String get note => _note;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  bool get isIncome => _type == TransactionType.income;
  bool get hasCategory => _category != null && _category!.trim().isNotEmpty;
  bool get hasValidAmount => _amount > 0;
  bool get canSubmit => hasValidAmount && hasCategory && !_isSubmitting;

  void setType(TransactionType type) {
    if (_type == type) return;
    _type = type;
    notifyListeners();
  }

  void toggleType() {
    setType(
      _type == TransactionType.expense
          ? TransactionType.income
          : TransactionType.expense,
    );
  }

  void setAmount(double value) {
    if (_amount == value) return;
    _amount = value;
    notifyListeners();
  }

  void setAmountFromString(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '').trim());
    setAmount(parsed ?? 0);
  }

  void setCategory(String? value) {
    if (_category == value) return;
    _category = value;
    notifyListeners();
  }

  void setDate(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    if (_date.isAtSameMomentAs(normalized)) return;
    _date = normalized;
    notifyListeners();
  }

  void setNote(String value) {
    final trimmed = value.trim();
    if (_note == trimmed) return;
    _note = trimmed;
    notifyListeners();
  }

  void reset() {
    _type = TransactionType.expense;
    _amount = 0;
    _category = null;
    _date = DateTime.now();
    _note = '';
    _isSubmitting = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> submit() async {
    if (!canSubmit) return false;
    if (_isSubmitting) return false;

    _setSubmitting(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await addTransactionUseCase(
        type: _type,
        amount: _amount,
        category: _category!,
        date: DateTime(_date.year, _date.month, _date.day, 12),
        note: _note.isEmpty ? null : _note,
      );
      reset();
      return true;
    } on DataFailure catch (failure) {
      _errorMessage = failure.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not save the transaction. Please try again.';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  void _setSubmitting(bool value) {
    if (_isSubmitting == value) return;
    _isSubmitting = value;
    notifyListeners();
  }
}