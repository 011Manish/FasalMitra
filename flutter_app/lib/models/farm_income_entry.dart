class FarmIncomeEntry {
  final String id;
  final String userId;
  final String farmId;
  final String description;
  final double amount;
  final DateTime entryDate;

  FarmIncomeEntry({
    required this.id,
    required this.userId,
    required this.farmId,
    required this.description,
    required this.amount,
    required this.entryDate,
  });

  factory FarmIncomeEntry.fromMap(Map<String, dynamic> row) => FarmIncomeEntry(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        farmId: row['farm_id'] as String,
        description: row['description'] as String,
        amount: (row['amount'] as num).toDouble(),
        entryDate: DateTime.parse(row['entry_date'] as String),
      );
}
