class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    this.body,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String kind;
  final String title;
  final String? body;

  /// Ids for opening the related screen, e.g. `listing_id`, `enquiry_id`, `product_id`.
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromMap(Map<String, dynamic> row) => AppNotification(
        id: row['id'] as String,
        kind: row['kind'] as String,
        title: row['title'] as String,
        body: row['body'] as String?,
        data: Map<String, dynamic>.from(row['data'] as Map),
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
        readAt: row['read_at'] == null
            ? null
            : DateTime.parse(row['read_at'] as String).toLocal(),
      );
}
