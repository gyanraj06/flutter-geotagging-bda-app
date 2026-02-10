import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '../../models/geo_entry.dart';
import '../../core/utils.dart';
import '../export/image_export_service.dart';

class EntryDetailScreen extends StatelessWidget {
  final GeoEntry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(entry.category)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _downloadImage(context),
        child: const Icon(Icons.download),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full Image
            GestureDetector(
              onTap: () => _showFullImage(context),
              child: SizedBox(
                height: 300,
                child: entry.imagePath.isNotEmpty
                    ? Image.file(
                        File(entry.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 64),
                                SizedBox(height: 8),
                                Text('Image not found'),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 64),
                        ),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(entry.category),
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.2),
                      ),
                      Text(
                        AppUtils.formatDate(entry.timestamp),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Address
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: const Text('Address'),
                    subtitle: Text(entry.address),
                  ),

                  // Coordinates
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.my_location, color: Colors.blue),
                    title: const Text('Coordinates'),
                    subtitle: Text(
                      'Lat: ${entry.latitude.toStringAsFixed(6)}\nLng: ${entry.longitude.toStringAsFixed(6)}',
                    ),
                  ),

                  // Accuracy & Altitude
                  if (entry.accuracy != null || entry.altitude != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.gps_fixed, color: Colors.green),
                      title: const Text('GPS Details'),
                      subtitle: Text(
                        'Accuracy: ${entry.accuracy?.toStringAsFixed(1) ?? 'N/A'}m\nAltitude: ${entry.altitude?.toStringAsFixed(1) ?? 'N/A'}m',
                      ),
                    ),

                  // Notes
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notes, color: Colors.orange),
                      title: const Text('Notes'),
                      subtitle: Text(entry.note!),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Mini Map
                  const Text(
                    'Location on Map',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(
                            entry.latitude,
                            entry.longitude,
                          ),
                          initialZoom: 15.0,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.geotagpro.geotag_pro',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(entry.latitude, entry.longitude),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Image Path (for debugging)
                  ExpansionTile(
                    title: const Text('Technical Details'),
                    children: [
                      ListTile(
                        title: const Text('Image Path'),
                        subtitle: Text(
                          entry.imagePath,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      ListTile(
                        title: const Text('Synced'),
                        subtitle: Text(entry.synced ? 'Yes' : 'No'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadImage(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing image for export...')),
    );

    try {
      // Export logic here
      await ImageExportService.exportAndShare([entry], null);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _showFullImage(BuildContext context) {
    if (entry.imagePath.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preparing image for export...'),
                    ),
                  );
                  try {
                    await ImageExportService.exportAndShare([entry], null);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Export failed: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                File(entry.imagePath),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text(
                    'Image not found',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
