import 'dart:io';
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/stencil_model.dart';
import '../storage/file_storage_service.dart';
import '../image/image_processor.dart';

/// Repository for managing stencil data (Hive + File System)
class StencilRepository {
  final Box<StencilModel> _stencilBox;
  final FileStorageService _fileStorage;
  final _uuid = const Uuid();
  
  StencilRepository({
    required Box<StencilModel> stencilBox,
    required FileStorageService fileStorage,
  })  : _stencilBox = stencilBox,
        _fileStorage = fileStorage;
  
  /// Create new stencil from image file
  Future<StencilModel> createStencil({
    required File imageFile,
    required double widthCm,
    String? name,
  }) async {
    try {
      final id = _uuid.v4();
      
      // 1. Save original image
      final originalPath = await _fileStorage.saveOriginalImage(imageFile);
      
      // 2. Read image bytes
      final imageBytes = await imageFile.readAsBytes();
      
      // 3. Get dimensions
      final dimensions = ImageProcessor.getImageDimensions(imageBytes);
      if (dimensions == null) {
        throw Exception('Failed to read image dimensions');
      }
      
      // 4. Calculate height maintaining aspect ratio
      final aspectRatio = dimensions['height']! / dimensions['width']!;
      final heightCm = widthCm * aspectRatio;
      
      // 5. Generate thumbnail
      final thumbnailBytes = await ImageProcessor.generateThumbnail(imageBytes);
      final thumbnailPath = await _fileStorage.saveThumbnail(thumbnailBytes, id);
      
      // 6. Process initial stencil (default settings)
      final processedBytes = await ImageProcessor.processStencil(
        originalBytes: imageBytes,
        contrast: 60,
      );
      final processedPath = await _fileStorage.saveProcessedImage(processedBytes, id);
      
      // 7. Generate name if not provided
      final stencilName = name ?? 'Stencil ${DateTime.now().day}/${DateTime.now().month}';
      
      // 8. Create model
      final stencil = StencilModel(
        id: id,
        name: stencilName,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        originalImagePath: originalPath,
        processedImagePath: processedPath,
        thumbnailPath: thumbnailPath,
        widthCm: widthCm,
        heightCm: heightCm,
      );
      
      // 9. Save to Hive
      await _stencilBox.put(id, stencil);
      
      debugPrint('✅ Stencil created: $stencilName ($widthCm × $heightCm cm)');
      
      return stencil;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to create stencil: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }
  
  /// Update stencil parameters and reprocess image
  Future<StencilModel> updateStencil({
    required String id,
    String? name,
    double? widthCm,
    bool? isMirroredH,
    bool? isMirroredV,
    int? rotationDegrees,
    int? contrastLevel,
    int? brightnessLevel,
    String? paperSize,
    String? clientNote,
    bool? isFavorite,
  }) async {
    try {
      final existing = _stencilBox.get(id);
      if (existing == null) {
        throw Exception('Stencil not found: $id');
      }
      
      // Calculate new height if width changed
      double newHeightCm = existing.heightCm;
      if (widthCm != null && widthCm != existing.widthCm) {
        final aspectRatio = existing.heightCm / existing.widthCm;
        newHeightCm = widthCm * aspectRatio;
      }
      
      // Create updated model
      final updated = existing.copyWith(
        name: name ?? existing.name,
        widthCm: widthCm ?? existing.widthCm,
        heightCm: newHeightCm,
        isMirroredH: isMirroredH ?? existing.isMirroredH,
        isMirroredV: isMirroredV ?? existing.isMirroredV,
        rotationDegrees: rotationDegrees ?? existing.rotationDegrees,
        contrastLevel: contrastLevel ?? existing.contrastLevel,
        brightnessLevel: brightnessLevel ?? existing.brightnessLevel,
        paperSize: paperSize ?? existing.paperSize,
        clientNote: clientNote ?? existing.clientNote,
        isFavorite: isFavorite ?? existing.isFavorite,
        lastModifiedAt: DateTime.now(),
      );
      
      // Reprocess image if visual parameters changed
      final needsReprocessing = isMirroredH != null ||
          isMirroredV != null ||
          rotationDegrees != null ||
          contrastLevel != null ||
          brightnessLevel != null;
      
      if (needsReprocessing) {
        final originalBytes = await _fileStorage.readFile(existing.originalImagePath);
        
        final processedBytes = await ImageProcessor.processStencil(
          originalBytes: originalBytes,
          mirrorH: updated.isMirroredH,
          mirrorV: updated.isMirroredV,
          rotation: updated.rotationDegrees,
          contrast: updated.contrastLevel,
          brightness: updated.brightnessLevel,
        );
        
        await _fileStorage.saveProcessedImage(processedBytes, id);
        
        debugPrint('🔄 Reprocessed stencil: ${updated.name}');
      }
      
      // Save to Hive
      await _stencilBox.put(id, updated);
      
      debugPrint('✅ Stencil updated: ${updated.name}');
      
      return updated;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to update stencil: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }
  
  /// Get stencil by ID
  StencilModel? getStencil(String id) {
    return _stencilBox.get(id);
  }
  
  /// Get all stencils (sorted by last modified)
  List<StencilModel> getAllStencils({bool favoritesFirst = false}) {
    final stencils = _stencilBox.values.toList();
    
    stencils.sort((a, b) {
      if (favoritesFirst) {
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;
      }
      return b.lastModifiedAt.compareTo(a.lastModifiedAt);
    });
    
    return stencils;
  }
  
  /// Search stencils by name
  List<StencilModel> searchStencils(String query) {
    if (query.isEmpty) return getAllStencils();
    
    final lowercaseQuery = query.toLowerCase();
    return _stencilBox.values
        .where((s) =>
            s.name.toLowerCase().contains(lowercaseQuery) ||
            (s.clientNote?.toLowerCase().contains(lowercaseQuery) ?? false))
        .toList()
      ..sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));
  }
  
  /// Delete stencil (also deletes files)
  Future<void> deleteStencil(String id) async {
    try {
      final stencil = _stencilBox.get(id);
      if (stencil == null) return;
      
      // Delete files
      await _fileStorage.deleteStencilFiles(
        originalPath: stencil.originalImagePath,
        processedPath: stencil.processedImagePath,
        thumbnailPath: stencil.thumbnailPath,
      );
      
      // Delete from Hive
      await _stencilBox.delete(id);
      
      debugPrint('🗑️ Stencil deleted: ${stencil.name}');
    } catch (e) {
      debugPrint('❌ Failed to delete stencil: $e');
      rethrow;
    }
  }
  
  /// Duplicate stencil
  Future<StencilModel> duplicateStencil(String id) async {
    try {
      final original = _stencilBox.get(id);
      if (original == null) {
        throw Exception('Stencil not found: $id');
      }
      
      final newId = _uuid.v4();
      
      // Copy files
      final originalImageBytes = await _fileStorage.readFile(original.originalImagePath);
      final processedImageBytes = await _fileStorage.readFile(original.processedImagePath);
      
      final newOriginalPath = await _fileStorage.saveProcessedImage(originalImageBytes, '$newId-original');
      final newProcessedPath = await _fileStorage.saveProcessedImage(processedImageBytes, newId);
      
      String? newThumbnailPath;
      if (original.thumbnailPath != null) {
        final thumbnailBytes = await _fileStorage.readFile(original.thumbnailPath!);
        newThumbnailPath = await _fileStorage.saveThumbnail(thumbnailBytes, newId);
      }
      
      // Create duplicate
      final duplicate = original.copyWith(
        id: newId,
        name: '${original.name} (Copy)',
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        originalImagePath: newOriginalPath,
        processedImagePath: newProcessedPath,
        thumbnailPath: newThumbnailPath,
      );
      
      await _stencilBox.put(newId, duplicate);
      
      debugPrint('✅ Stencil duplicated: ${duplicate.name}');
      
      return duplicate;
    } catch (e) {
      debugPrint('❌ Failed to duplicate stencil: $e');
      rethrow;
    }
  }
  
  /// Mark stencil as exported
  Future<void> markAsExported(String id) async {
    final stencil = _stencilBox.get(id);
    if (stencil == null) return;
    
    final updated = stencil.copyWith(lastExportedAt: DateTime.now());
    await _stencilBox.put(id, updated);
  }
  
  /// Get storage statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final stencils = _stencilBox.values.toList();
    final storageStats = await _fileStorage.getStorageStats();
    
    final totalSize = storageStats.values.reduce((a, b) => a + b);
    
    return {
      'totalStencils': stencils.length,
      'favorites': stencils.where((s) => s.isFavorite).length,
      'exportedCount': stencils.where((s) => s.lastExportedAt != null).length,
      'storageUsedMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'storageByType': storageStats.map(
        (key, value) => MapEntry(key, (value / (1024 * 1024)).toStringAsFixed(2)),
      ),
    };
  }
  
  /// Cleanup (called on app start)
  Future<void> cleanup() async {
    await _fileStorage.cleanupOldExports();
  }
}
