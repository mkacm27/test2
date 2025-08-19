import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../helpers/database_helper.dart';

class TransactionProvider with ChangeNotifier {
  List<PrintTransaction> _transactions = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<PrintTransaction> get transactions => _transactions;

  Future<void> fetchTransactions({
    String? className,
    String? instructorName,
    String? date,
    String? query,
  }) async {
    _transactions = await _dbHelper.getTransactions(
      className: className,
      instructorName: instructorName,
      date: date,
      query: query,
    );
    notifyListeners();
  }

  Future<void> addTransaction(PrintTransaction transaction) async {
    await _dbHelper.insertTransaction(transaction);
    await fetchTransactions(); // Refresh the list
  }

  Future<void> updateTransaction(PrintTransaction transaction) async {
    await _dbHelper.updateTransaction(transaction);
    await fetchTransactions(); // Refresh the list
  }

  Future<void> deleteTransaction(int id) async {
    await _dbHelper.deleteTransaction(id);
    await fetchTransactions(); // Refresh the list
  }
  
  Future<List<Map<String, dynamic>>> getMonthlyReport(int year, int month) async {
    return await _dbHelper.getMonthlyReport(year, month);
  }
}
