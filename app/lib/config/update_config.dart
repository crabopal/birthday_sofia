/// Where the installed APK looks for newer builds.
///
/// After this PR is merged into `main`, keep [gitRef] as `main` so every
/// push of `dist/version.json` + APK becomes an OTA update.
class UpdateConfig {
  static const gitRef = 'main';

  static const repo = 'crabopal/birthday_sofia';

  static String get manifestUrl =>
      'https://raw.githubusercontent.com/$repo/$gitRef/dist/version.json';

  static String defaultApkUrl(String fileName) =>
      'https://github.com/$repo/raw/$gitRef/dist/$fileName';
}
