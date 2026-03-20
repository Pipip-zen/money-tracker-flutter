class TransactionEntity {
  final int id;
  final double amount;
  final String? note;
  final DateTime date;
  final String type;
  final int categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;

  const TransactionEntity({
    required this.id,
    required this.amount,
    this.note,
    required this.date,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });
}
