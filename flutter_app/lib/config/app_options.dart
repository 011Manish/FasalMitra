/// App-wide switches.
abstract final class AppOptions {
  /// true: the intro slides ("Scan & Check Crop Leaves" and so on) show every
  /// time the app is opened while nobody is logged in, and again right after
  /// logging out. Handy while testing the design.
  /// false: they show only the very first time the app is opened.
  /// Set this to false before you publish the app.
  static const bool showIntroEveryLaunch = true;
}
