import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '../../models/geo_entry.dart';
import '../gallery/gallery_provider.dart';
import '../../core/utils.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(galleryEntriesProvider);

    final markers = entries.map((entry) {
      return Marker(
        point: LatLng(entry.latitude, entry.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showEntryDetails(context, entry),
          child: const Icon(
            Icons.location_on,
            color: Colors.blueGrey,
            size: 40,
          ),
        ),
      );
    }).toList();

    final initialCenter = entries.isNotEmpty
        ? LatLng(entries.first.latitude, entries.first.longitude)
        : const LatLng(0, 0);

    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: entries.isNotEmpty ? 13.0 : 2.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.geotagpro.geotag_pro',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Center map logic could be added here
        },
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  void _showEntryDetails(BuildContext context, GeoEntry entry) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        height: 300,
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(entry.imagePath),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.error),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.category,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(AppUtils.formatDate(entry.timestamp)),
                      const SizedBox(height: 4),
                      Text(
                        entry.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            if (entry.note != null && entry.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  entry.note!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
