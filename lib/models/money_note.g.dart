import 'package:flutter/foundation.dart';
import '../models/money_note.dart';
import '../services/database_service.dart';
import '../utils/currency_converter.dart';

class MoneyNoteModelProvider with ChangeNotifier {
  List<MoneyNote> _moneyNotes = [];

  List<MoneyNote> get moneyNotes => [..._moneyNotes];

  MoneyNoteModelProvider() {
    loadMoneyNotes();
  }

  Future<void> loadMoneyNotes() async {
    _moneyNotes = await DatabaseService.getMoneyNotes();
    notifyListeners();
  }

  Future<void> addMoneyNote(MoneyNote moneyNote) async {
    await DatabaseService.addMoneyNote(moneyNote);
    await loadMoneyNotes();
  }

  Future<void> updateMoneyNote(MoneyNote moneyNote) async {
    await DatabaseService.updateMoneyNote(moneyNote);
    await loadMoneyNotes();
  }

  Future<void> deleteMoneyNote(String id) async {
    await DatabaseService.deleteMoneyNote(id);
    await loadMoneyNotes();
  }

  double get totalToReceive {
    return _moneyNotes
        .where((note) => note.type == 'gave' && note.status == 'open')
        .fold(0.0, (sum, note) => sum + note.remainingAmount);
  }

  double get totalToPay {
    return _moneyNotes
        .where((note) => note.type == 'took' && note.status == 'open')
        .fold(0.0, (sum, note) => sum + note.remainingAmount);
  }

  List<MoneyNote> get openNotes {
    return _moneyNotes.where((note) => note.status == 'open').toList();
  }

  List<MoneyNote> get settledNotes {
    return _moneyNotes.where((note) => note.status == 'settled').toList();
  }

  List<MoneyNote> get gaveNotes {
    return _moneyNotes.where((note) => note.type == 'gave').toList();
  }

  List<MoneyNote> get tookNotes {
    return _moneyNotes.where((note) => note.type == 'took').toList();
  }

  Future<void> settleMoneyNote(String id) async {
    final note = _moneyNotes.firstWhere((n) => n.id == id);
    final settledNote = note.copyWith(
      status: 'settled',
      remainingAmount: 0.0,
    );
    await updateMoneyNote(settledNote);
  }

  Future<void> partialPayment(String id, double amount) async {
    final note = _moneyNotes.firstWhere((n) => n.id == id);
    final newRemaining = note.remainingAmount - amount;

    final updatedNote = note.copyWith(
      remainingAmount: newRemaining > 0 ? newRemaining : 0.0,
      status: newRemaining <= 0 ? 'settled' : 'open',
    );

    await updateMoneyNote(updatedNote);
  }

  // Convert all money notes when currency changes
  Future<void> convertAllMoneyNotes(
      String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return;

    for (var note in _moneyNotes) {
      final convertedAmount = CurrencyConverter.convert(
        note.amount,
        fromCurrency,
        toCurrency,
      );

      final convertedRemaining = CurrencyConverter.convert(
        note.remainingAmount,
        fromCurrency,
        toCurrency,
      );

      final updatedNote = note.copyWith(
        amount: convertedAmount,
        remainingAmount: convertedRemaining,
      );

      await DatabaseService.updateMoneyNote(updatedNote);
    }

    await loadMoneyNotes();
  }
}
