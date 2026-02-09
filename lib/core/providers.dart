import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../services/location_service.dart';

final camerasProvider = Provider<List<CameraDescription>>(
  (ref) => throw UnimplementedError(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
