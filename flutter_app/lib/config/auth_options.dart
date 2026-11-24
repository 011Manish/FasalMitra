/// Sign-in options. Phone-code login needs a paid SMS provider in Supabase
/// (Authentication, Sign In / Providers, Phone). Set this to true only after
/// that provider is configured and the cost is approved.
abstract final class AuthOptions {
  static const bool phoneLogin = false;
}
