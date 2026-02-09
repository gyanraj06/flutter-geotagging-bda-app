import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '../../models/geo_entry.dart';
import '../../services/database_service.dart';
import '../../core/utils.dart';
// import '../../services/location_service.dart';
import '../../core/providers.dart';
import '../gallery/gallery_provider.dart';

class AddMetadataScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final String initialAddress;

  const AddMetadataScreen({
    super.key,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.initialAddress,
  });

  @override
  ConsumerState<AddMetadataScreen> createState() => _AddMetadataScreenState();
}

class _AddMetadataScreenState extends ConsumerState<AddMetadataScreen> {
  final _noteController = TextEditingController();
  String _selectedCategory = GeoEntry.categories.first;
  late LatLng _currentPosition;
  late String _currentAddress;
  bool _isSaving = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _currentPosition = LatLng(widget.latitude, widget.longitude);
    _currentAddress = widget.initialAddress;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _updateLocation(LatLng newPosition) async {
    setState(() {
      _currentPosition = newPosition;
    });

    final locService = ref.read(locationServiceProvider);
    final address = await locService.getAddressFromCoordinates(
      newPosition.latitude,
      newPosition.longitude,
    );
    if (mounted) {
      setState(() {
        _currentAddress = address;
      });
    }
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final entry = GeoEntry()
        ..imagePath = widget.imagePath
        ..latitude = _currentPosition.latitude
        ..longitude = _currentPosition.longitude
        ..accuracy = widget.accuracy
        ..altitude = widget.altitude
        ..timestamp = DateTime.now()
        ..address = _currentAddress
        ..note = _noteController.text
        ..category = _selectedCategory
        ..synced = false;

      final dbService = ref.read(databaseServiceProvider);
      await dbService.addEntry(entry);

      if (mounted) {
        // Invalidate the gallery provider to refresh the list
        ref.invalidate(galleryEntriesProvider);
        // Navigate back to home/gallery
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Details'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview
            SizedBox(
              height: 250,
              child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Map Preview (Editable)
                  SizedBox(
                    height: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentPosition,
                          initialZoom: 15.0,
                          onTap: (tapPosition, point) {
                            _updateLocation(point);
                          },
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
                                point: _currentPosition,
                                width: 80,
                                height: 80,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.blueGrey,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap map to adjust location",
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Address
                  ListTile(
                    leading: const Icon(
                      Icons.location_on,
                      color: Colors.blueGrey,
                    ),
                    title: Text(_currentAddress),
                    subtitle: Text(
                      AppUtils.formatCoordinates(
                        _currentPosition.latitude,
                        _currentPosition.longitude,
                      ),
                    ),
                  ),
                  const Divider(),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: GeoEntry.categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Note
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50), // bottom padding
          ],
        ),
      ),
    );
  }
}
