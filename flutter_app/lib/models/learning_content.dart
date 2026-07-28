class LearningContent {
  final String id;
  final String contentType;
  final String title;
  final String summary;
  final String body;
  final String? externalUrl;

  LearningContent({
    required this.id,
    required this.contentType,
    required this.title,
    required this.summary,
    required this.body,
    this.externalUrl,
  });

  factory LearningContent.fromMap(Map<String, dynamic> row) => LearningContent(
        id: row['id'] as String,
        contentType: row['content_type'] as String,
        title: row['title'] as String,
        summary: row['summary'] as String,
        body: row['body'] as String,
        externalUrl: row['external_url'] as String?,
      );
}

const learningContentTypes = ['course', 'video', 'ebook', 'success_story'];
