/// Where the installed APK looks for newer builds.
class UpdateConfig {
  static const gitRef = 'cursor/sonya-birthday-game-apk-922d';

  static const repo = 'crabopal/birthday_sofia';

  static String get manifestUrl =>
      'https://raw.githubusercontent.com/$repo/$gitRef/dist/version.json';

  static String defaultApkUrl(String fileName) =>
      'https://github.com/$repo/raw/$gitRef/dist/$fileName';
}
