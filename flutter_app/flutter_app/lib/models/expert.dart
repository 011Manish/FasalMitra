class Expert {
  final String id;
  final String name;
  final String specialty;
  final String bio;
  final String? photoUrl;

  Expert({
    required this.id,
    required this.name,
    required this.specialty,
    required this.bio,
    this.photoUrl,
  });

  factory Expert.fromMap(Map<String, dynamic> row) => Expert(
        id: row['id'] as String,
        name: row['name'] as String,
        specialty: row['specialty'] as String,
        bio: row['bio'] as String,
        photoUrl: row['photo_url'] as String?,
      );
}
