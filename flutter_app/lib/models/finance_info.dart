class FinanceInfo {
  final String id;
  final String category;
  final String title;
  final String body;

  FinanceInfo({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
  });

  factory FinanceInfo.fromMap(Map<String, dynamic> row) => FinanceInfo(
        id: row['id'] as String,
        category: row['category'] as String,
        title: row['title'] as String,
        body: row['body'] as String,
      );
}

const financeCategories = ['insurance', 'loan', 'subsidy'];
