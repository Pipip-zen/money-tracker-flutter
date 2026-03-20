class TransactionEntity {
  final int id;
  final double amount;
  final String? note;
  final DateTime date;
  final String type;
  final int categoryId;
  final String categoryName;
  final int categoryIcon;
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

  TransactionEntity copyWith({
    int? id,
    double? amount,
    String? note,
    DateTime? date,
    String? type,
    int? categoryId,
    String? categoryName,
    int? categoryIcon,
    String? categoryColor,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }
}
