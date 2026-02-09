// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geo_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GeoEntryAdapter extends TypeAdapter<GeoEntry> {
  @override
  final int typeId = 0;

  @override
  GeoEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GeoEntry()
      ..imagePath = fields[0] as String
      ..latitude = fields[1] as double
      ..longitude = fields[2] as double
      ..accuracy = fields[3] as double?
      ..altitude = fields[4] as double?
      ..timestamp = fields[5] as DateTime
      ..address = fields[6] as String
      ..note = fields[7] as String?
      ..category = fields[8] as String
      ..synced = fields[9] as bool;
  }

  @override
  void write(BinaryWriter writer, GeoEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.imagePath)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.accuracy)
      ..writeByte(4)
      ..write(obj.altitude)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.address)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
