import 'dart:math';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/models/money_note.dart';
import 'package:smartexpense/models/bill.dart';

class MockDataGenerator {
  static final Random _random = Random();

  // Sample category IDs (will be replaced with actual ones from database)
  static const List<String> _categoryIds = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
  ];

  static const List<String> _personNames = [
    'John Doe',
    'Jane Smith',
    'Mike Johnson',
    'Sarah Williams',
    'David Brown',
    'Emma Davis',
    'Chris Wilson',
    'Lisa Anderson',
  ];

  static const List<String> _billNames = [
    'Electricity Bill',
    'Water Bill',
    'Internet Bill',
    'Mobile Bill',
    'Netflix Subscription',
    'Spotify Premium',
    'Gym Membership',
    'House Rent',
  ];

  static const List<String> _expenseNotes = [
    'Grocery shopping',
    'Lunch with friends',
    'Coffee break',
    'Fuel for car',
    'Birthday gift',
    'Movie tickets',
    'Online shopping',
    'Restaurant dinner',
  ];

  static const List<String> _moneyNoteNotes = [
    'Emergency loan',
    'Birthday gift money',
    'Business payment',
    'Borrowed for trip',
    'Salary advance',
    'Medical expenses',
    'Party expenses',
    'Shopping money',
  ];

  // Generate expenses for last 3 months
  static List<Expense> generateExpenses() {
    final expenses = <Expense>[];
    final now = DateTime.now();

    // Generate 50-80 expenses over last 3 months
    final count = 50 + _random.nextInt(31);

    for (int i = 0; i < count; i++) {
      // Random date within last 90 days
      final daysAgo = _random.nextInt(90);
      final date = now.subtract(Duration(days: daysAgo));

      final expense = Expense(
        id: '${DateTime.now().millisecondsSinceEpoch}_$i',
        amount: _generateRandomAmount(50, 5000),
        categoryId: _categoryIds[_random.nextInt(_categoryIds.length)],
        date: date,
        note: _random.nextBool()
            ? _expenseNotes[_random.nextInt(_expenseNotes.length)]
            : null,
      );

      expenses.add(expense);
    }

    return expenses;
  }

  // Generate money notes
  static List<MoneyNote> generateMoneyNotes() {
    final notes = <MoneyNote>[];
    final now = DateTime.now();

    // Generate 10-15 money notes
    final count = 10 + _random.nextInt(6);

    for (int i = 0; i < count; i++) {
      final daysAgo = _random.nextInt(60);
      final date = now.subtract(Duration(days: daysAgo));

      final type = _random.nextBool() ? 'gave' : 'took';
      final status =
          _random.nextInt(10) < 7 ? 'open' : 'settled'; // 70% open, 30% settled

      final amount = _generateRandomAmount(500, 10000);
      final remainingAmount = status == 'settled'
          ? 0.0
          : amount - (_random.nextDouble() * amount * 0.5);

      final note = MoneyNote(
        id: '${DateTime.now().millisecondsSinceEpoch}_$i',
        amount: amount,
        remainingAmount: remainingAmount,
        personName: _personNames[_random.nextInt(_personNames.length)],
        date: date,
        type: type,
        status: status,
        note: _random.nextBool()
            ? _moneyNoteNotes[_random.nextInt(_moneyNoteNotes.length)]
            : null,
      );

      notes.add(note);
    }

    return notes;
  }

  // Generate bills
  static List<Bill> generateBills() {
    final bills = <Bill>[];
    final now = DateTime.now();

    // Generate 8-12 bills
    final count = 8 + _random.nextInt(5);

    for (int i = 0; i < count; i++) {
      // Random due date in next 30 days
      final daysAhead = _random.nextInt(30);
      final dueDate = now.add(Duration(days: daysAhead));

      final repeatTypes = ['once', 'weekly', 'monthly', 'yearly'];
      final repeatType = repeatTypes[_random.nextInt(repeatTypes.length)];

      // Determine status based on due date
      String status;
      if (daysAhead < 0) {
        status = 'overdue';
      } else if (_random.nextInt(10) < 2) {
        status = 'paid'; // 20% chance of being paid
      } else {
        status = 'upcoming';
      }

      final bill = Bill(
        id: '${DateTime.now().millisecondsSinceEpoch}_$i',
        name: _billNames[i % _billNames.length],
        amount: _generateRandomAmount(500, 3000),
        categoryId: _categoryIds[_random.nextInt(_categoryIds.length)],
        dueDate: dueDate,
        repeatType: repeatType,
        status: status,
        note: _random.nextBool() ? 'Auto-generated bill' : null,
      );

      bills.add(bill);
    }

    return bills;
  }

  // Helper: Generate random amount
  static double _generateRandomAmount(double min, double max) {
    final amount = min + _random.nextDouble() * (max - min);
    return double.parse(amount.toStringAsFixed(2));
  }

  // Generate realistic category-specific amounts
  // ignore: unused_element
  static double _getCategoryAmount(String categoryId) {
    switch (categoryId) {
      case '1': // Food
        return _generateRandomAmount(50, 500);
      case '2': // Transport
        return _generateRandomAmount(30, 300);
      case '3': // Shopping
        return _generateRandomAmount(100, 2000);
      case '4': // Entertainment
        return _generateRandomAmount(100, 1000);
      case '5': // Health
        return _generateRandomAmount(200, 3000);
      case '6': // Education
        return _generateRandomAmount(500, 5000);
      case '7': // Bills
        return _generateRandomAmount(500, 3000);
      default: // Other
        return _generateRandomAmount(50, 1000);
    }
  }

  // Generate specific date patterns
  // ignore: unused_element
  static DateTime _generateDateInMonth(int monthsAgo) {
    final now = DateTime.now();
    final targetMonth = DateTime(now.year, now.month - monthsAgo, 1);
    final daysInMonth =
        DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final randomDay = 1 + _random.nextInt(daysInMonth);

    return DateTime(
      targetMonth.year,
      targetMonth.month,
      randomDay,
      _random.nextInt(24),
      _random.nextInt(60),
    );
  }
}
