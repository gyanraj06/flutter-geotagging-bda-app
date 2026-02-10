import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils.dart';
import '../../models/geo_entry.dart';
import 'dart:io';

import 'gallery_provider.dart';
import '../export/export_service.dart';
import '../export/image_export_service.dart';
import 'entry_detail_screen.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(galleryEntriesProvider);
    final currentCategory = ref.watch(galleryCategoryFilterProvider);
    final currentDateRange = ref.watch(galleryDateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoTag Pro Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onPressed: () {
              if (entries.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No entries to export')),
                );
                return;
              }
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Export Data'),
                  content: const Text('Choose export format:'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ExportService.exportToCsv(entries);
                      },
                      child: const Text('CSV'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ExportService.exportToPdf(entries);
                      },
                      child: const Text('PDF'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _exportImagesToGallery(context, entries);
                      },
                      child: const Text('Images'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    label: Text(currentCategory ?? 'All Categories'),
                    avatar: const Icon(Icons.filter_list),
                    onPressed: () async {
                      final selected = await showDialog<String>(
                        context: context,
                        builder: (ctx) => SimpleDialog(
                          title: const Text('Filter by Category'),
                          children: [
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(ctx, null),
                              child: const Text('All Categories'),
                            ),
                            ...GeoEntry.categories.map(
                              (c) => SimpleDialogOption(
                                onPressed: () => Navigator.pop(ctx, c),
                                child: Text(c),
                              ),
                            ),
                          ],
                        ),
                      );
                      ref.read(galleryCategoryFilterProvider.notifier).state =
                          selected;
                    },
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: Text(
                      currentDateRange == null
                          ? 'All Dates'
                          : '${AppUtils.formatDate(currentDateRange.start)} - ${AppUtils.formatDate(currentDateRange.end)}',
                    ),
                    avatar: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      ref.read(galleryDateRangeProvider.notifier).state = range;
                    },
                  ),
                  if (currentCategory != null || currentDateRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        ref.read(galleryCategoryFilterProvider.notifier).state =
                            null;
                        ref.read(galleryDateRangeProvider.notifier).state =
                            null;
                      },
                    ),
                ],
              ),
            ),
          ),

          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('No entries found. Start capturing!'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: entry.imagePath.isNotEmpty
                                ? Image.file(
                                    File(entry.imagePath),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image),
                                  )
                                : const Icon(Icons.image_not_supported),
                          ),
                          title: Text(
                            entry.category,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppUtils.formatDate(entry.timestamp)),
                              Text(
                                entry.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Export Entry'),
                                  content: const Text('Choose export format:'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        ExportService.exportToCsv([entry]);
                                      },
                                      child: const Text('CSV'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        ExportService.exportToPdf([entry]);
                                      },
                                      child: const Text('PDF'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _exportImagesToGallery(context, [
                                          entry,
                                        ]);
                                      },
                                      child: const Text('Image'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EntryDetailScreen(entry: entry),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _exportImagesToGallery(BuildContext context, List<GeoEntry> entries) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ExportProgressDialog(entries: entries),
    );
  }
}

class _ExportProgressDialog extends StatefulWidget {
  final List<GeoEntry> entries;

  const _ExportProgressDialog({required this.entries});

  @override
  State<_ExportProgressDialog> createState() => _ExportProgressDialogState();
}

class _ExportProgressDialogState extends State<_ExportProgressDialog> {
  int _current = 0;
  int _total = 0;
  bool _isExporting = true;

  @override
  void initState() {
    super.initState();
    _total = widget.entries.length;
    _startExport();
  }

  Future<void> _startExport() async {
    await ImageExportService.exportAndShare(widget.entries, (current, total) {
      if (mounted) {
        setState(() {
          _current = current;
          _total = total;
        });
      }
    });

    if (mounted) {
      setState(() => _isExporting = false);
      Navigator.pop(context); // Close dialog after share sheet opens
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Preparing Images...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _total > 0 ? _current / _total : 0),
          const SizedBox(height: 16),
          Text('Processing $_current of $_total'),
          const SizedBox(height: 8),
          const Text(
            'Adding location details to images...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
