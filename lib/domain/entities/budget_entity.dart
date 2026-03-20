class BudgetEntity {
  final int id;
  final int categoryId;
  final double limitAmount;
  final int month;
  final int year;
  final double? spentAmount;

  const BudgetEntity({
    required this.id,
    required this.categoryId,
    required this.limitAmount,
    required this.month,
    required this.year,
    this.spentAmount,
  });
}
