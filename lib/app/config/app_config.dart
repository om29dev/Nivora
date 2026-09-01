class AppConfig {
  AppConfig._();

  static const String appName = 'Nivora';
  static const String appTagline = 'Code without the desk.';
  static const String appVersion = '1.0.0';

  // Storage Directories
  static const String projectsDirName = 'projects';
  static const String indexesDirName = 'indexes';
  static const String cacheDirName = 'cache';

  // AI & Budget Configuration
  static const int maxContextTokens = 4000;
  static const int terminalMaxLines = 2000;
  static const Duration terminalDebounceDuration = Duration(milliseconds: 30);

  // Preference Keys
  static const String prefOnboardingCompleted = 'onboarding_completed';
  static const String prefSelectedAiProvider = 'selected_ai_provider';
  static const String prefRecentProjects = 'recent_projects';
  static const String prefThemeMode = 'theme_mode';
}
