import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/geo_entry.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('Override in main.dart');
});

class DatabaseService {
  final Box<GeoEntry> _box;

  DatabaseService(this._box);

  // Create
  Future<void> addEntry(GeoEntry entry) async {
    await _box.add(entry);
  }

  // Read all
  List<GeoEntry> getAllEntries() {
    return _box.values.toList();
  }

  // Watch all entries
  Stream<List<GeoEntry>> watchAllEntries() {
    return _box.watch().map((_) => _box.values.toList());
  }

  // Get by key
  GeoEntry? getEntry(int key) {
    return _box.get(key);
  }

  // Update
  Future<void> updateEntry(GeoEntry entry) async {
    await entry.save();
  }

  // Delete
  Future<void> deleteEntry(GeoEntry entry) async {
    await entry.delete();
  }

  // Delete by key
  Future<void> deleteEntryByKey(int key) async {
    await _box.delete(key);
  }

  // Get entries by category
  List<GeoEntry> getEntriesByCategory(String category) {
    return _box.values.where((e) => e.category == category).toList();
  }

  // Get unsynced entries
  List<GeoEntry> getUnsyncedEntries() {
    return _box.values.where((e) => !e.synced).toList();
  }
}
