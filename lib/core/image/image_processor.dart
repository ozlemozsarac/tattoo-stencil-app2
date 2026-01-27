import 'dart:typed_data';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Image processing operations (runs in isolate for performance)
class ImageProcessor {
  /// Load image from bytes
  static img.Image? loadImage(Uint8List bytes) {
    return img.decodeImage(bytes);
  }
  
  /// Mirror horizontal (flip left-right)
  static Future<Uint8List> mirrorHorizontal(Uint8List imageBytes) async {
    return await compute(_mirrorHorizontalIsolate, imageBytes);
  }
  
  static Uint8List _mirrorHorizontalIsolate(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    
    final mirrored = img.flipHorizontal(image);
    return Uint8List.fromList(img.encodePng(mirrored));
  }
  
  /// Mirror vertical (flip top-bottom)
  static Future<Uint8List> mirrorVertical(Uint8List imageBytes) async {
    return await compute(_mirrorVerticalIsolate, imageBytes);
  }
  
  static Uint8List _mirrorVerticalIsolate(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    
    final mirrored = img.flipVertical(image);
    return Uint8List.fromList(img.encodePng(mirrored));
  }
  
  /// Rotate image by degrees (0, 90, 180, 270)
  static Future<Uint8List> rotate(Uint8List imageBytes, int degrees) async {
    return await compute(
      _rotateIsolate,
      {'bytes': imageBytes, 'degrees': degrees},
    );
  }
  
  static Uint8List _rotateIsolate(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final degrees = params['degrees'] as int;
    
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    
    final angle = degrees * (3.14159 / 180); // Convert to radians
    final rotated = img.copyRotate(image, angle: angle);
    
    return Uint8List.fromList(img.encodePng(rotated));
  }
  
  /// Adjust contrast (-100 to +100)
  static Future<Uint8List> adjustContrast(
    Uint8List imageBytes,
    int level,
  ) async {
    return await compute(
      _adjustContrastIsolate,
      {'bytes': imageBytes, 'level': level},
    );
  }
  
  static Uint8List _adjustContrastIsolate(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final level = params['level'] as int;
    
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    
    // Convert level (0-100) to contrast value (0.5 - 2.0)
    final contrast = 0.5 + (level / 100) * 1.5;
    
    final adjusted = img.adjustColor(image, contrast: contrast);
    return Uint8List.fromList(img.encodePng(adjusted));
  }
  
  /// Adjust brightness (-50 to +50)
  static Future<Uint8List> adjustBrightness(
    Uint8List imageBytes,
    int level,
  ) async {
    return await compute(
      _adjustBrightnessIsolate,
      {'bytes': imageBytes, 'level': level},
    );
  }
  
  static Uint8List _adjustBrightnessIsolate(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final level = params['level'] as int;
    
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    
    // Convert level to brightness value
    final brightness = level.toDouble();
    
    final adjusted = img.adjustColor(image, brightness: brightness);
    return Uint8List.fromList(img.encodePng(adjusted));
  }
  
  /// Resize image (maintain aspect ratio if height is null)
  static Future<Uint8List> resize(
    Uint8List imageBytes, {
    required int width,
    int? height,
  }) async {
    return await compute(
      _resizeIsolate,
      {'bytes': imageBytes, 'width': width, 'height': height},
    );
  }
  
  static Uint8List _resizeIsolate(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final width = params['width'] as int;
    final height = params['height'] as int?;
    
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    
    final resized = img.copyResize(
      image,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );
    
    return Uint8List.fromList(img.encodePng(resized));
  }
  
  /// Generate thumbnail (200x200)
  static Future<Uint8List> generateThumbnail(Uint8List imageBytes) async {
    return await resize(imageBytes, width: 200, height: 200);
  }
  
  /// Convert to grayscale
  static Future<Uint8List> toGrayscale(Uint8List imageBytes) async {
    return await compute(_toGrayscaleIsolate, imageBytes);
  }
  
  static Uint8List _toGrayscaleIsolate(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    
    final grayscale = img.grayscale(image);
    return Uint8List.fromList(img.encodePng(grayscale));
  }
  
  /// Apply threshold (for thermal printers - pure black/white)
  static Future<Uint8List> applyThreshold(
    Uint8List imageBytes, {
    int threshold = 128,
  }) async {
    return await compute(
      _applyThresholdIsolate,
      {'bytes': imageBytes, 'threshold': threshold},
    );
  }
  
  static Uint8List _applyThresholdIsolate(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final threshold = params['threshold'] as int;
    
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    
    // First convert to grayscale
    final gray = img.grayscale(image);
    
    // Apply threshold
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final pixel = gray.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        
        // If darker than threshold, make black, else white
        final newPixel = luminance < threshold
            ? img.ColorRgb8(0, 0, 0)
            : img.ColorRgb8(255, 255, 255);
        
        gray.setPixel(x, y, newPixel);
      }
    }
    
    return Uint8List.fromList(img.encodePng(gray));
  }
  
  /// Crop image
  static Future<Uint8List> crop(
    Uint8List imageBytes, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    return await compute(
      _cropIsolate,
      {
        'bytes': imageBytes,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      },
    );
  }
  
  static Uint8List _cropIsolate(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final x = params['x'] as int;
    final y = params['y'] as int;
    final width = params['width'] as int;
    final height = params['height'] as int;
    
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    
    final cropped = img.copyCrop(image, x: x, y: y, width: width, height: height);
    return Uint8List.fromList(img.encodePng(cropped));
  }
  
  /// Get image dimensions
  static Map<String, int>? getImageDimensions(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return null;
    
    return {
      'width': image.width,
      'height': image.height,
    };
  }
  
  /// Process image with all transformations
  static Future<Uint8List> processStencil({
    required Uint8List originalBytes,
    bool mirrorH = false,
    bool mirrorV = false,
    int rotation = 0,
    int contrast = 60,
    int brightness = 0,
    bool forThermalPrinter = false,
  }) async {
    return await compute(
      _processStencilIsolate,
      {
        'bytes': originalBytes,
        'mirrorH': mirrorH,
        'mirrorV': mirrorV,
        'rotation': rotation,
        'contrast': contrast,
        'brightness': brightness,
        'forThermal': forThermalPrinter,
      },
    );
  }
  
  static Uint8List _processStencilIsolate(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    var image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    
    // Apply transformations in order
    
    // 1. Rotation
    final rotation = params['rotation'] as int;
    if (rotation != 0) {
      final angle = rotation * (3.14159 / 180);
      image = img.copyRotate(image, angle: angle);
    }
    
    // 2. Mirror
    if (params['mirrorH'] as bool) {
      image = img.flipHorizontal(image);
    }
    if (params['mirrorV'] as bool) {
      image = img.flipVertical(image);
    }
    
    // 3. Brightness
    final brightness = params['brightness'] as int;
    if (brightness != 0) {
      image = img.adjustColor(image, brightness: brightness.toDouble());
    }
    
    // 4. Contrast
    final contrast = params['contrast'] as int;
    final contrastValue = 0.5 + (contrast / 100) * 1.5;
    image = img.adjustColor(image, contrast: contrastValue);
    
    // 5. Thermal printer optimization (grayscale + threshold)
    if (params['forThermal'] as bool) {
      image = img.grayscale(image);
      
      // Apply threshold
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final luminance = img.getLuminance(pixel);
          
          final newPixel = luminance < 128
              ? img.ColorRgb8(0, 0, 0)
              : img.ColorRgb8(255, 255, 255);
          
          image.setPixel(x, y, newPixel);
        }
      }
    }
    
    return Uint8List.fromList(img.encodePng(image));
  }
}
