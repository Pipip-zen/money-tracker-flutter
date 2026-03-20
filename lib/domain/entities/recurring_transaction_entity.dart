class RecurringTransactionEntity {
  final int id;
  final double amount;
  final String? note;
  final String type;
  final int categoryId;
  final String frequency;
  final DateTime nextDueDate;
  final bool isActive;

  const RecurringTransactionEntity({
    required this.id,
    required this.amount,
    this.note,
    required this.type,
    required this.categoryId,
    required this.frequency,
    required this.nextDueDate,
    required this.isActive,
  });
}
