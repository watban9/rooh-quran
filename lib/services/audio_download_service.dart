
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class AudioDownloadService {
  static final Dio _dio = Dio();

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

    await _dio.download(
      url,
      filePath,
      deleteOnError: true,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress?.call(received / total);
        }
      },
    );

    return filePath;
  }

  static Future<bool> isDownloaded(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/rooh_audio/$fileName',
    );

    return file.exists();
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
