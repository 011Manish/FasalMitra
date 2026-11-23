class LearningContent {
  final String id;
  final String contentType;
  final String title;
  final String summary;
  final String body;
  final String? externalUrl;
  final String category;
  final String language;
  final String? thumbnailUrl;

  LearningContent({
    required this.id,
    required this.contentType,
    required this.title,
    required this.summary,
    required this.body,
    this.externalUrl,
    this.category = 'general',
    this.language = 'en',
    this.thumbnailUrl,
  });

  factory LearningContent.fromMap(Map<String, dynamic> row) => LearningContent(
        id: row['id'] as String,
        contentType: row['content_type'] as String,
        title: row['title'] as String,
        summary: row['summary'] as String,
        body: row['body'] as String,
        externalUrl: row['external_url'] as String?,
        category: (row['category'] as String?) ?? 'general',
        language: (row['language'] as String?) ?? 'en',
        thumbnailUrl: row['thumbnail_url'] as String?,
      );
}

const learningContentTypes = ['course', 'video', 'ebook', 'success_story'];

const videoContentType = 'video';

/// Order matters: this is the order of the filter chips.
const learningCategoryLabels = <String, String>{
  'general': 'General',
  'vegetable_farming': 'Vegetable farming',
  'rice': 'Rice',
  'maize': 'Maize',
  'soil_testing': 'Soil testing',
  'compost_fertilizer': 'Compost & fertilizer',
  'irrigation': 'Irrigation',
  'pest_disease': 'Pest & disease',
  'harvesting_selling': 'Harvesting & selling',
};

const learningLanguageLabels = <String, String>{
  'ne': 'Nepali',
  'hi': 'Hindi',
  'en': 'English',
};
