import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../providers/transaction_provider.dart';
import '../models/transaction.dart'; // يحتوي على PrintTransaction
import 'add_edit_transaction_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  _TransactionListScreenState createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedClass;
  String? _selectedInstructor;
  DateTime? _selectedDate;

  final List<String> _classes = ['All', 'A', 'B', 'C', 'D', 'E', 'F', 'G'];
  final List<String> _instructors = ['All', 'Ahmed', 'Youssef', 'Khalil', 'Imad'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterTransactions);
  }

  void _filterTransactions() {
    Provider.of<TransactionProvider>(context, listen: false).fetchTransactions(
      query: _searchController.text,
      className: _selectedClass == 'All' ? null : _selectedClass,
      instructorName: _selectedInstructor == 'All' ? null : _selectedInstructor,
      date: _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020), 
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _filterTransactions();
    }
  }
  
  Future<void> _generateAndSharePdf(PrintTransaction tx) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Print Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Transaction ID: ${tx.id}'),
              pw.Text('Date: ${DateFormat.yMd().add_jm().format(tx.transactionDate)}'),
              pw.Text('Class: ${tx.className}'),
              pw.Text('Instructor: ${tx.instructorName}'),
              pw.Text('Copies: ${tx.copies}'),
              pw.Text('Print Type: ${tx.printType}'),
              pw.Divider(height: 20),
              pw.Text('Total Cost: ${tx.totalCost.toStringAsFixed(2)}'),
              pw.Text('Paid Amount: ${tx.paidAmount.toStringAsFixed(2)}'),
              pw.Text('Remaining: ${tx.remainingBalance.toStringAsFixed(2)}'),
              pw.SizedBox(height: 20),
              pw.Text('Status: ${tx.paymentStatus}', style: pw.TextStyle(fontSize: 18, color: tx.paymentStatus == 'Paid' ? PdfColors.green : PdfColors.red)),
            ]
          );
        }
      )
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/receipt_${tx.id}.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Here is your print receipt.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search by Class or Instructor',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    DropdownButton<String>(
                      value: _selectedClass ?? 'All',
                      items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        setState(() => _selectedClass = val);
                        _filterTransactions();
                      },
                    ),
                    DropdownButton<String>(
                      value: _selectedInstructor ?? 'All',
                      items: _instructors.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                      onChanged: (val) {
                        setState(() => _selectedInstructor = val);
                        _filterTransactions();
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_selectedDate == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                if (provider.transactions.isEmpty) {
                  return const Center(child: Text('No transactions found.'));
                }
                return ListView.builder(
                  itemCount: provider.transactions.length,
                  itemBuilder: (context, index) {
                    final tx = provider.transactions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text('${tx.className} - ${tx.instructorName}'),
                        subtitle: Text('${DateFormat.yMd().format(tx.transactionDate)} - Copies: ${tx.copies}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${tx.totalCost.toStringAsFixed(2)}', style: TextStyle(color: tx.paymentStatus == 'Paid' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditTransactionScreen(transaction: tx)))),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () => provider.deleteTransaction(tx.id!)),
                            IconButton(icon: const Icon(Icons.receipt), onPressed: () => _generateAndSharePdf(tx)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
