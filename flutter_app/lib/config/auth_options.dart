/// Sign-in options. Phone-code login needs a paid SMS provider in Supabase
/// (Authentication, Sign In / Providers, Phone). Set this to true only after
/// that provider is configured and the cost is approved.
abstract final class AuthOptions {
  static const bool phoneLogin = false;

  /// Email code login, as in the Figma design (6-digit code for sign up and
  /// password reset). Leave this false until the email templates in Supabase
  /// (Authentication, Email Templates: Confirm signup and Reset Password) show
  /// the code with {{ .Token }} instead of a link. While it is false the app
  /// uses the confirmation and reset links, exactly as before.
  static const bool emailCodes = false;
}
