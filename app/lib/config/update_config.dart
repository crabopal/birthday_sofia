/// Where the installed APK looks for newer builds.
class UpdateConfig {
  static const gitRef = 'cursor/sonya-birthday-game-apk-922d';

  static const repo = 'crabopal/birthday_sofia';

  /// Branch names with `/` must be URL-encoded as a single path segment.
  static String get encodedRef => Uri.encodeComponent(gitRef);

  static String get manifestUrl =>
      'https://raw.githubusercontent.com/$repo/$encodedRef/dist/version.json';

  static String defaultApkUrl(String fileName) =>
      'https://raw.githubusercontent.com/$repo/$encodedRef/dist/$fileName';
}
