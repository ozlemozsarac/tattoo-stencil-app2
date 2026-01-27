import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

/// File storage service for managing stencil images
class FileStorageService {
  static const String _baseDir = 'stencil_app';
  static const String _originalsDir = 'originals';
  static const String _processedDir = 'processed';
  static const String _exportsDir = 'exports';
  static const String _cacheDir = 'cache';
  
  final _uuid = const Uuid();
  
  /// Get base directory path
  Future<String> get _basePath async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$_baseDir';
  }
  
  /// Initialize directory structure
  Future<void> initialize() async {
    final base = await _basePath;
    final dirs = [
      '$base/$_originalsDir',
      '$base/$_processedDir',
      '$base/$_exportsDir',
      '$base/$_cacheDir',
    ];
    
    for (final dir in dirs) {
      await Directory(dir).create(recursive: true);
    }
    
    debugPrint('📁 File storage initialized at: $base');
  }
  
  /// Save original image
  Future<String> saveOriginalImage(File imageFile) async {
    final base = await _basePath;
    final ext = imageFile.path.split('.').last;
    final filename = '${_uuid.v4()}.$ext';
    final targetPath = '$base/$_originalsDir/$filename';
    
    await imageFile.copy(targetPath);
    
    debugPrint('✅ Original saved: $filename');
    return '$_originalsDir/$filename';
  }
  
  /// Save processed image
  Future<String> saveProcessedImage(Uint8List imageData, String id) async {
    final base = await _basePath;
    final filename = '$id.png';
    final targetPath = '$base/$_processedDir/$filename';
    
    await File(targetPath).writeAsBytes(imageData);
    
    debugPrint('✅ Processed saved: $filename');
    return '$_processedDir/$filename';
  }
  
  /// Save thumbnail
  Future<String> saveThumbnail(Uint8List imageData, String id) async {
    final base = await _basePath;
    final filename = '$id-thumb.jpg';
    final targetPath = '$base/$_cacheDir/$filename';
    
    await File(targetPath).writeAsBytes(imageData);
    
    debugPrint('✅ Thumbnail saved: $filename');
    return '$_cacheDir/$filename';
  }
  
  /// Get full path from relative path
  Future<String> getFullPath(String relativePath) async {
    final base = await _basePath;
    return '$base/$relativePath';
  }
  
  /// Read file as bytes
  Future<Uint8List> readFile(String relativePath) async {
    final fullPath = await getFullPath(relativePath);
    return await File(fullPath).readAsBytes();
  }
  
  /// Delete file
  Future<void> deleteFile(String relativePath) async {
    final fullPath = await getFullPath(relativePath);
    final file = File(fullPath);
    
    if (await file.exists()) {
      await file.delete();
      debugPrint('🗑️ Deleted: $relativePath');
    }
  }
  
  /// Delete stencil files (original, processed, thumbnail)
  Future<void> deleteStencilFiles({
    required String originalPath,
    required String processedPath,
    String? thumbnailPath,
  }) async {
    await Future.wait([
      deleteFile(originalPath),
      deleteFile(processedPath),
      if (thumbnailPath != null) deleteFile(thumbnailPath),
    ]);
  }
  
  /// Cleanup old export files (older than 7 days)
  Future<void> cleanupOldExports() async {
    final base = await _basePath;
    final exportsDir = Directory('$base/$_exportsDir');
    
    if (!await exportsDir.exists()) return;
    
    final now = DateTime.now();
    final files = await exportsDir.list().toList();
    
    int deletedCount = 0;
    
    for (final file in files) {
      if (file is File) {
        final stat = await file.stat();
        final age = now.difference(stat.modified);
        
        if (age.inDays > 7) {
          await file.delete();
          deletedCount++;
        }
      }
    }
    
    if (deletedCount > 0) {
      debugPrint('🧹 Cleaned up $deletedCount old export files');
    }
  }
  
  /// Get storage usage stats
  Future<Map<String, int>> getStorageStats() async {
    final base = await _basePath;
    
    int getDirectorySize(String path) {
      final dir = Directory(path);
      if (!dir.existsSync()) return 0;
      
      int size = 0;
      dir.listSync(recursive: true).forEach((entity) {
        if (entity is File) {
          size += entity.lengthSync();
        }
      });
      return size;
    }
    
    return {
      'originals': getDirectorySize('$base/$_originalsDir'),
      'processed': getDirectorySize('$base/$_processedDir'),
      'exports': getDirectorySize('$base/$_exportsDir'),
      'cache': getDirectorySize('$base/$_cacheDir'),
    };
  }
}
