import 'dart:io';
import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/services/export_import/models/export_import_models.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileManager {
  static const String _tag = 'FileManager';

  // Share export file
  static Future<bool> shareExport(ExportResult result) async {
    if (!result.success || result.data == null) return false;

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${result.fileName}');
      await file.writeAsString(result.data!);

      final xFile = XFile(file.path);
      final shareResult = await Share.shareXFiles(
        [xFile],
        subject: '${AppConstants.appName} Backup',
        text: '${AppConstants.appName} backup with ${result.itemCount} items',
      );

      await file.delete();

      return shareResult.status == ShareResultStatus.success;
    } catch (e) {
      DebugLogger.error('Failed to share export', tag: _tag, error: e);
      return false;
    }
  }

  // Save to device
  static Future<String?> saveToDevice(ExportResult result) async {
    if (!result.success || result.data == null) return null;

    try {
      DebugLogger.info('Saving to device', tag: _tag);

      Directory? directory;

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Documents');
        if (!await directory.exists()) {
          directory = Directory('/storage/emulated/0/Download');
        }
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) return null;

      // Create organized folder structure
      final monthFolder = DateFormat('yyyy-MM').format(DateTime.now());
      final dayflowDir = Directory(
        '${directory.path}/${AppConstants.appName}/$monthFolder',
      );

      if (!await dayflowDir.exists()) {
        await dayflowDir.create(recursive: true);
      }

      // Save file
      final filePath = '${dayflowDir.path}/${result.fileName}';
      final file = File(filePath);
      await file.writeAsString(result.data!);

      DebugLogger.success('File saved', tag: _tag, data: filePath);
      return filePath;
    } catch (e) {
      DebugLogger.error('Failed to save to device', tag: _tag, error: e);
      return null;
    }
  }

  // Pick file for import
  static Future<String?> pickFileForImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.importExtensions,
        withData: true,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        DebugLogger.success(
          'File picked',
          tag: _tag,
          data: result.files.single.name,
        );
        return content;
      }

      return null;
    } catch (e) {
      DebugLogger.error('Failed to pick file', tag: _tag, error: e);
      return null;
    }
  }

  // Get backup files
  static Future<List<FileInfo>> getBackupFiles() async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        directory = Directory(
          '/storage/emulated/0/Documents/${AppConstants.appName}',
        );
        if (!await directory.exists()) {
          directory = Directory(
            '/storage/emulated/0/Download/${AppConstants.appName}',
          );
        }
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        directory = Directory('${appDir.path}/${AppConstants.appName}');
      }

      if (!await directory.exists()) {
        return [];
      }

      final files = <FileInfo>[];
      final entities = await directory.list(recursive: true).toList();

      for (final entity in entities) {
        if (entity is File) {
          final path = entity.path;
          if (path.endsWith('.json') || path.endsWith('.csv')) {
            final stat = await entity.stat();
            files.add(
              FileInfo(
                path: path,
                name: path.split('/').last,
                size: stat.size,
                modified: stat.modified,
              ),
            );
          }
        }
      }

      files.sort((a, b) => b.modified.compareTo(a.modified));
      return files;
    } catch (e) {
      DebugLogger.error('Failed to get backup files', tag: _tag, error: e);
      return [];
    }
  }

  // Delete backup file
  static Future<bool> deleteBackupFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        DebugLogger.success('File deleted', tag: _tag, data: path);
        return true;
      }
      return false;
    } catch (e) {
      DebugLogger.error('Failed to delete file', tag: _tag, error: e);
      return false;
    }
  }
}

class FileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime modified;

  FileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.modified,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
