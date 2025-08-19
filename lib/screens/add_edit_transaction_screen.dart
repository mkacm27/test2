
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as app_transaction;
import '../providers/transaction_provider.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final app_transaction.Transaction? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  _AddEditTransactionScreenState createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _copiesController;
  late TextEditingController _paidAmountController;

  String? _className;
  String? _instructorName;
  String? _printType;
  double _totalCost = 0.0;
  double _remainingBalance = 0.0;

  final List<String> _classes = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
  final List<String> _instructors = ['Ahmed', 'Youssef', 'Khalil', 'Imad'];
  final List<String> _printTypes = ['Recto', 'Recto Verso'];

  @override
  void initState() {
    super.initState();
    _copiesController = TextEditingController();
    _paidAmountController = TextEditingController();

    if (widget.transaction != null) {
      final t = widget.transaction!;
      _className = t.className;
      _instructorName = t.instructorName;
      _printType = t.printType;
      _copiesController.text = t.copies.toString();
      _paidAmountController.text = t.paidAmount.toString();
      _totalCost = t.totalCost;
      _remainingBalance = t.remainingBalance;
    }

    _copiesController.addListener(_calculateCosts);
    _paidAmountController.addListener(_calculateCosts);
  }

  void _calculateCosts() {
    final copies = int.tryParse(_copiesController.text) ?? 0;
    final paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;
    double costPerCopy = 0.0;

    if (_printType == 'Recto') {
      costPerCopy = 0.35;
    } else if (_printType == 'Recto Verso') {
      costPerCopy = 0.60;
    }

    setState(() {
      _totalCost = copies * costPerCopy;
      _remainingBalance = _totalCost - paidAmount;
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newTransaction = app_transaction.Transaction(
        id: widget.transaction?.id,
        transactionDate: widget.transaction?.transactionDate ?? DateTime.now(),
        className: _className!,
        instructorName: _instructorName!,
        copies: int.parse(_copiesController.text),
        printType: _printType!,
        totalCost: _totalCost,
        paidAmount: double.parse(_paidAmountController.text),
        remainingBalance: _remainingBalance,
        paymentStatus: _remainingBalance <= 0 ? 'Paid' : 'Unpaid',
      );

      final provider = Provider.of<TransactionProvider>(context, listen: false);
      if (widget.transaction == null) {
        provider.addTransaction(newTransaction);
      } else {
        provider.updateTransaction(newTransaction);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _copiesController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'New Transaction' : 'Edit Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildDropdown(_className, _classes, 'Class', (val) => setState(() => _className = val)),
              const SizedBox(height: 16),
              _buildDropdown(_instructorName, _instructors, 'Instructor', (val) => setState(() => _instructorName = val)),
              const SizedBox(height: 16),
              _buildDropdown(_printType, _printTypes, 'Print Type', (val) {
                setState(() => _printType = val);
                _calculateCosts();
              }),
              const SizedBox(height: 16),
              TextFormField(
                controller: _copiesController,
                decoration: const InputDecoration(labelText: 'Number of Copies', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Please enter number of copies' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paidAmountController,
                decoration: const InputDecoration(labelText: 'Paid Amount', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value == null || value.isEmpty ? 'Please enter paid amount' : null,
              ),
              const SizedBox(height: 24),
              _buildInfoRow('Total Cost:', '${_totalCost.toStringAsFixed(2)}'),
              _buildInfoRow('Remaining Balance:', '${_remainingBalance.toStringAsFixed(2)}'),
              _buildInfoRow('Payment Status:', _remainingBalance <= 0 ? 'Paid' : 'Unpaid'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Transaction'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String? currentValue, List<String> items, String label, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select a $label' : null,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
