
class Transaction {
  int? id;
  DateTime transactionDate;
  String className;
  String instructorName;
  int copies;
  String printType;
  double totalCost;
  double paidAmount;
  double remainingBalance;
  String paymentStatus;

  Transaction({
    this.id,
    required this.transactionDate,
    required this.className,
    required this.instructorName,
    required this.copies,
    required this.printType,
    required this.totalCost,
    required this.paidAmount,
    required this.remainingBalance,
    required this.paymentStatus,
  });

  // Convert a Transaction object into a Map object.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionDate': transactionDate.toIso8601String(),
      'className': className,
      'instructorName': instructorName,
      'copies': copies,
      'printType': printType,
      'totalCost': totalCost,
      'paidAmount': paidAmount,
      'remainingBalance': remainingBalance,
      'paymentStatus': paymentStatus,
    };
  }

  // Extract a Transaction object from a Map object.
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      transactionDate: DateTime.parse(map['transactionDate']),
      className: map['className'],
      instructorName: map['instructorName'],
      copies: map['copies'],
      printType: map['printType'],
      totalCost: map['totalCost'],
      paidAmount: map['paidAmount'],
      remainingBalance: map['remainingBalance'],
      paymentStatus: map['paymentStatus'],
    );
  }
}
