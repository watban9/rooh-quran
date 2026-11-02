import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class AudioDownloadService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 25),
      followRedirects: true,
      headers: {
        'User-Agent': 'ROOH-Quran-App/1.0',
      },
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  );

  static Future<String> downloadAudio({
    required String url,
    required String fileName,
    required void Function(double progress)? onProgress,
  }) async {
    final directory = await getApplicationDocumentsDirectory();

    final audioDirectory = Directory(
      '${directory.path}/rooh_audio',
    );

    if (!await audioDirectory.exists()) {
      await audioDirectory.create(recursive: true);
    }

    final safeName = fileName.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );

    final filePath = '${audioDirectory.path}/$safeName';
    final temporaryPath = '$filePath.part';

    try {
      await _dio.download(
        url,
        temporaryPath,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress?.call(received / total);
          }
        },
      );

      final temporaryFile = File(temporaryPath);

      if (!await temporaryFile.exists() ||
          await temporaryFile.length() == 0) {
        throw Exception('ملف الصوت فارغ أو لم يكتمل تنزيله');
      }

      final finalFile = File(filePath);

      if (await finalFile.exists()) {
        await finalFile.delete();
      }

      await temporaryFile.rename(filePath);

      return filePath;
    } catch (_) {
      final temporaryFile = File(temporaryPath);

      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }

      rethrow;
    }
  }

  static Future<bool> isDownloaded(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/rooh_audio/$fileName',
    );

    if (!await file.exists()) {
      return false;
    }

    return await file.length() > 0;
  }

  static Future<void> deleteAudio(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/rooh_audio/$fileName',
    );

    if (await file.exists()) {
      await file.delete();
    }
  }
}
