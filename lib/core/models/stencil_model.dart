import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'stencil_model.freezed.dart';
part 'stencil_model.g.dart';

@freezed
@HiveType(typeId: 1)
class StencilModel with _$StencilModel {
  const factory StencilModel({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required DateTime createdAt,
    @HiveField(3) required DateTime lastModifiedAt,
    
    // Image paths (relative)
    @HiveField(4) required String originalImagePath,
    @HiveField(5) required String processedImagePath,
    @HiveField(6) String? thumbnailPath,
    
    // Stencil parameters
    @HiveField(7) required double widthCm,
    @HiveField(8) required double heightCm,
    @HiveField(9) @Default(false) bool isMirroredH,
    @HiveField(10) @Default(false) bool isMirroredV,
    @HiveField(11) @Default(0) int rotationDegrees, // 0, 90, 180, 270
    @HiveField(12) @Default(60) int contrastLevel, // 0-100
    @HiveField(13) @Default(0) int brightnessLevel, // -50 to +50
    
    // Export info
    @HiveField(14) @Default('A4') String paperSize,
    @HiveField(15) DateTime? lastExportedAt,
    
    // Optional metadata
    @HiveField(16) String? clientNote,
    @HiveField(17) @Default(false) bool isFavorite,
  }) = _StencilModel;
  
  factory StencilModel.fromJson(Map<String, dynamic> json) =>
      _$StencilModelFromJson(json);
}

@freezed
@HiveType(typeId: 2)
class AppSettings with _$AppSettings {
  const factory AppSettings({
    // Printer settings
    @HiveField(0) @Default('A4') String defaultPaperSize,
    @HiveField(1) @Default(false) bool thermalPrinterMode,
    @HiveField(2) @Default(true) bool autoMirrorForThermal,
    
    // Default values
    @HiveField(3) @Default(60) int defaultContrastLevel,
    @HiveField(4) @Default(12.0) double defaultStencilWidthCm,
    
    // UI preferences
    @HiveField(5) @Default(true) bool darkModeEnabled,
    @HiveField(6) @Default(true) bool showRulerOverlay,
    @HiveField(7) @Default(true) bool addScaleTestPattern,
    
    // Feature flags
    @HiveField(8) @Default(false) bool enableTiledPrint,
    @HiveField(9) @Default(true) bool enableAutoSave,
  }) = _AppSettings;
  
  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
