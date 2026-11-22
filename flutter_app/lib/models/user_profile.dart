/// Allowed values mirror the database check constraints on `profiles`.
const profileCountries = {'NP': 'Nepal', 'IN': 'India'};
const profileLanguages = {'en': 'English', 'ne': 'Nepali'};
const profileRoles = {'farmer': 'Farmer', 'buyer': 'Buyer'};

class UserProfile {
  const UserProfile({
    this.fullName,
    this.phone,
    this.country,
    required this.preferredLanguage,
    required this.role,
  });

  final String? fullName;
  final String? phone;
  final String? country;
  final String preferredLanguage;
  final String role;

  bool get isAdmin => role == 'admin';

  factory UserProfile.fromMap(Map<String, dynamic> row) => UserProfile(
        fullName: row['full_name'] as String?,
        phone: row['phone'] as String?,
        country: row['country'] as String?,
        preferredLanguage: row['preferred_language'] as String,
        role: row['role'] as String,
      );

  /// The role is left out for admins so saving can never change it.
  Map<String, dynamic> toUpdate() => {
        'full_name': fullName,
        'phone': phone,
        'country': country,
        'preferred_language': preferredLanguage,
        if (!isAdmin) 'role': role,
      };
}
