class RecurringTransactionEntity {
  final int id;
  final double amount;
  final String? note;
  final String type;
  final int categoryId;
  final int? walletId;
  final String frequency;
  final DateTime nextDueDate;
  final bool isActive;

  const RecurringTransactionEntity({
    required this.id,
    required this.amount,
    this.note,
    required this.type,
    required this.categoryId,
    this.walletId,
    required this.frequency,
    required this.nextDueDate,
    required this.isActive,
  });
}
