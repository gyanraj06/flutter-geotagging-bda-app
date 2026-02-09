import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../models/geo_entry.dart';
import '../../services/database_service.dart';

final galleryCategoryFilterProvider = StateProvider<String?>((ref) => null);
final galleryDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final galleryEntriesProvider = Provider<List<GeoEntry>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final category = ref.watch(galleryCategoryFilterProvider);
  final dateRange = ref.watch(galleryDateRangeProvider);

  var entries = dbService.getAllEntries();

  if (category != null && category.isNotEmpty) {
    entries = entries.where((e) => e.category == category).toList();
  }
  if (dateRange != null) {
    entries = entries
        .where(
          (e) =>
              e.timestamp.isAfter(dateRange.start) &&
              e.timestamp.isBefore(dateRange.end.add(const Duration(days: 1))),
        )
        .toList();
  }

  entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return entries;
});
