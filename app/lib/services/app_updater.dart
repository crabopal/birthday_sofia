import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../config/update_config.dart';

class UpdateManifest {
  const UpdateManifest({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    this.notes,
  });

  final int versionCode;
  final String versionName;
  final String apkUrl;
  final String? notes;

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    return UpdateManifest(
      versionCode: json['versionCode'] as int,
      versionName: json['versionName'] as String? ?? '',
      apkUrl: json['apkUrl'] as String,
      notes: json['notes'] as String?,
    );
  }
}

enum UpdateCheckResult {
  upToDate,
  available,
  skipped,
  failed,
}

class UpdateCheck {
  const UpdateCheck({
    required this.result,
    this.manifest,
    this.localVersionCode,
    this.message,
  });

  final UpdateCheckResult result;
  final UpdateManifest? manifest;
  final int? localVersionCode;
  final String? message;
}

/// Checks GitHub-hosted version.json, downloads APK, opens system installer.
class AppUpdater {
  AppUpdater({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<UpdateCheck> check() async {
    if (kIsWeb || !Platform.isAndroid) {
      return const UpdateCheck(
        result: UpdateCheckResult.skipped,
        message: 'OTA только на Android TV',
      );
    }

    try {
      final info = await PackageInfo.fromPlatform();
      final localCode = int.tryParse(info.buildNumber) ?? 0;

      // GitHub raw serves text/plain — decode JSON manually.
      final response = await _dio.get<dynamic>(
        UpdateConfig.manifestUrl,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: const {'Accept': 'application/json, text/plain, */*'},
          followRedirects: true,
          validateStatus: (code) => code != null && code >= 200 && code < 400,
        ),
      );

      final raw = response.data;
      final Map<String, dynamic> data;
      if (raw is Map<String, dynamic>) {
        data = raw;
      } else if (raw is String) {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } else {
        return UpdateCheck(
          result: UpdateCheckResult.failed,
          localVersionCode: localCode,
          message: 'Неожиданный ответ манифеста',
        );
      }

      final manifest = UpdateManifest.fromJson(data);
      debugPrint(
        'OTA local=$localCode remote=${manifest.versionCode} '
        'url=${UpdateConfig.manifestUrl}',
      );

      if (manifest.versionCode > localCode) {
        return UpdateCheck(
          result: UpdateCheckResult.available,
          manifest: manifest,
          localVersionCode: localCode,
        );
      }
      return UpdateCheck(
        result: UpdateCheckResult.upToDate,
        manifest: manifest,
        localVersionCode: localCode,
        message: 'Локально $localCode ≥ ${manifest.versionCode}',
      );
    } catch (e) {
      debugPrint('Update check failed: $e');
      return UpdateCheck(
        result: UpdateCheckResult.failed,
        message: e.toString(),
      );
    }
  }

  /// Downloads [manifest.apkUrl] and launches the package installer.
  Future<void> downloadAndInstall(
    UpdateManifest manifest, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sonya-birthday-update.apk');
    if (await file.exists()) {
      await file.delete();
    }

    await _dio.download(
      manifest.apkUrl,
      file.path,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress?.call(received / total);
        }
      },
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        receiveTimeout: const Duration(minutes: 10),
      ),
    );

    final length = await file.length();
    if (length < 1000) {
      throw StateError('Скачанный файл слишком маленький ($length байт)');
    }

    final result = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw StateError('Не удалось открыть установщик: ${result.message}');
    }
  }
}
