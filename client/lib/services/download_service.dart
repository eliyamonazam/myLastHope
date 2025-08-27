import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadService {
  Future<void> downloadSong(BuildContext context,
      {required String url, required String fileName}) async {
    bool hasPermission = await _requestPermission();

    if (hasPermission) {
      // ۱. پیدا کردن مسیر صحیح برای ذخیره‌سازی
      Directory? directory = await getDownloadsDirectory();
      if (directory == null) {
        _showSnackBar(context, 'Could not find download directory.');
        return;
      }

      // ساختن یک پوشه مخصوص برای اپ در پوشه دانلودها
      final musicFolderPath = '${directory.path}/MyMusicApp';
      final musicDir = Directory(musicFolderPath);
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      final savePath =
          '${musicDir.path}/${fileName.endsWith('.mp3') ? fileName : '$fileName.mp3'}';

      // ۲. شروع دانلود
      try {
        _showSnackBar(context, 'Starting download: $fileName');
        await Dio().download(url, savePath);
        _showSnackBar(context,
            'Download complete! Saved to Downloads/MyMusicApp folder.');
      } on DioException catch (e) {
        print(e.message);
        _showSnackBar(context, 'Error while downloading file.');
      }
    } else {
      _showSnackBar(context, 'Storage permission denied.');
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt >= 33) {
        // For Android 13+, storage permission is managed differently
        return true;
      }
    }
    var status = await Permission.storage.request();
    return status.isGranted;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
