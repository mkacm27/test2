
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'print_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionDate TEXT NOT NULL,
        className TEXT NOT NULL,
        instructorName TEXT NOT NULL,
        copies INTEGER NOT NULL,
        printType TEXT NOT NULL,
        totalCost REAL NOT NULL,
        paidAmount REAL NOT NULL,
        remainingBalance REAL NOT NULL,
        paymentStatus TEXT NOT NULL
      )
      ''');
  }

  // Insert a transaction
  Future<int> insertTransaction(Transaction transaction) async {
    Database db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  // Update a transaction
  Future<int> updateTransaction(Transaction transaction) async {
    Database db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // Delete a transaction
  Future<int> deleteTransaction(int id) async {
    Database db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get all transactions with optional filters
  Future<List<Transaction>> getTransactions({
    String? className,
    String? instructorName,
    String? date,
    String? query,
  }) async {
    Database db = await database;
    List<Map<String, dynamic>> maps;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (className != null && className.isNotEmpty) {
      whereClause += 'className = ?';
      whereArgs.add(className);
    }
    if (instructorName != null && instructorName.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'instructorName = ?';
      whereArgs.add(instructorName);
    }
    if (date != null && date.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += "strftime('%Y-%m-%d', transactionDate) = ?";
      whereArgs.add(date);
    }
    if (query != null && query.isNotEmpty) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += '(className LIKE ? OR instructorName LIKE ?)';
        whereArgs.add('%$query%');
        whereArgs.add('%$query%');
    }

    maps = await db.query(
      'transactions',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'transactionDate DESC',
    );

    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  // Get monthly report data
  Future<List<Map<String, dynamic>>> getMonthlyReport(int year, int month) async {
    Database db = await database;
    String startDate = DateTime(year, month, 1).toIso8601String();
    String endDate = DateTime(year, month + 1, 0).toIso8601String();

    return await db.rawQuery('''
      SELECT
        className,
        SUM(copies) as totalCopies,
        SUM(totalCost) as totalCost
      FROM transactions
      WHERE transactionDate BETWEEN ? AND ?
      GROUP BY className
    ''', [startDate, endDate]);
  }
}
