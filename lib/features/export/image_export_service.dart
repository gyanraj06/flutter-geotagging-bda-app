import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/geo_entry.dart';
import '../../core/utils.dart';

class ImageExportService {
  /// Export images with details overlay and share them (user can save to gallery)
  static Future<void> exportAndShare(
    List<GeoEntry> entries,
    void Function(int, int)? onProgress,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory('${tempDir.path}/geotag_export');

    // Create export directory
    if (await exportDir.exists()) {
      await exportDir.delete(recursive: true);
    }
    await exportDir.create();

    final List<XFile> filesToShare = [];

    for (int i = 0; i < entries.length; i++) {
      onProgress?.call(i + 1, entries.length);

      try {
        final entry = entries[i];
        final originalFile = File(entry.imagePath);

        if (!await originalFile.exists()) continue;

        final bytes = await originalFile.readAsBytes();
        final originalImage = img.decodeImage(bytes);
        if (originalImage == null) continue;

        // Add text overlay
        final processedImage = _addTextOverlay(originalImage, entry);

        // Encode and save
        final outputBytes = img.encodeJpg(processedImage, quality: 90);
        final fileName =
            'GeoTag_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final outputFile = File('${exportDir.path}/$fileName');
        await outputFile.writeAsBytes(outputBytes);

        filesToShare.add(XFile(outputFile.path));
      } catch (e) {
        debugPrint('Error processing image $i: $e');
      }
    }

    if (filesToShare.isNotEmpty) {
      await Share.shareXFiles(
        filesToShare,
        text:
            'GeoTag Pro Export - ${filesToShare.length} images with location data',
      );
    }
  }

  /// Add text overlay to bottom of image
  static img.Image _addTextOverlay(img.Image original, GeoEntry entry) {
    // Calculate overlay height
    final overlayHeight = (original.height * 0.12).clamp(80, 200).toInt();

    // Create new image with extra space at bottom
    final newHeight = original.height + overlayHeight;
    final result = img.Image(width: original.width, height: newHeight);

    // Fill with white background
    img.fill(result, color: img.ColorRgb8(255, 255, 255));

    // Copy original image to top
    img.compositeImage(result, original, dstX: 0, dstY: 0);

    // Draw dark overlay bar at bottom
    img.fillRect(
      result,
      x1: 0,
      y1: original.height,
      x2: original.width,
      y2: newHeight,
      color: img.ColorRgba8(30, 30, 30, 240),
    );

    // Calculate text positioning
    final padding = 15;
    var yPos = original.height + padding;
    final lineHeight = 22;
    final textColor = img.ColorRgb8(255, 255, 255);

    // Format the text lines
    final dateStr = AppUtils.formatDate(entry.timestamp);
    final coordStr =
        '${entry.latitude.toStringAsFixed(5)}, ${entry.longitude.toStringAsFixed(5)}';

    // Draw address (truncated)
    final address = _truncate(entry.address, 50);
    img.drawString(
      result,
      address,
      font: img.arial24,
      x: padding,
      y: yPos,
      color: textColor,
    );
    yPos += lineHeight;

    // Draw date and category
    final dateCategory = '$dateStr | ${entry.category}';
    img.drawString(
      result,
      dateCategory,
      font: img.arial14,
      x: padding,
      y: yPos,
      color: img.ColorRgb8(200, 200, 200),
    );
    yPos += lineHeight - 4;

    // Draw coordinates
    img.drawString(
      result,
      coordStr,
      font: img.arial14,
      x: padding,
      y: yPos,
      color: img.ColorRgb8(150, 150, 150),
    );

    // Draw branding
    img.drawString(
      result,
      'GeoTag',
      font: img.arial14,
      x: original.width - 90,
      y: newHeight - 20,
      color: img.ColorRgb8(100, 100, 100),
    );

    return result;
  }

  static String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}
