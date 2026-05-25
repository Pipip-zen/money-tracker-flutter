enum WalletType {
  cash,
  bank,
  ewallet,
  custom,
}

class Wallet {
  final int id;
  final String name;
  final WalletType type;
  final String iconName;
  final String colorHex;
  final double initialBalance;
  final String currency;
  final bool isDefault;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? currentBalance;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.iconName,
    required this.colorHex,
    required this.initialBalance,
    required this.currency,
    required this.isDefault,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.currentBalance,
  });

  Wallet copyWith({
    int? id,
    String? name,
    WalletType? type,
    String? iconName,
    String? colorHex,
    double? initialBalance,
    String? currency,
    bool? isDefault,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? currentBalance,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      initialBalance: initialBalance ?? this.initialBalance,
      currency: currency ?? this.currency,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }
}
