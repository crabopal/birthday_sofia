import 'dart:io';

/// Media refs:
/// - `assets/...` — bundled in the APK
/// - `user:filename` — file in the app documents media folder
class MediaPaths {
  static bool isAsset(String? path) =>
      path != null && path.startsWith('assets/');

  static bool isUser(String? path) => path != null && path.startsWith('user:');

  static String userRef(String filename) => 'user:$filename';

  static String userFilename(String path) {
    if (!isUser(path)) return path;
    return path.substring('user:'.length);
  }

  static File resolveUserFile(Directory mediaDir, String path) {
    return File('${mediaDir.path}/${userFilename(path)}');
  }

  static String displayName(String? path) {
    if (path == null || path.isEmpty) return '—';
    if (isUser(path)) return userFilename(path);
    if (isAsset(path)) return path.split('/').last;
    return path;
  }
}
