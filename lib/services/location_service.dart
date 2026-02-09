import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<bool> handlePermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await handlePermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      // Handle timeout or other errors
      return null;
    }
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}, ${place.country ?? ''}"
            .replaceAll(RegExp(r'^, |,\s*,|,\s*$'), '')
            .trim();
      }
    } catch (e) {
      // Intentionally empty - allow fallback
    }
    // Fallback if geocoding fails (e.g. no internet)
    return "${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}";
  }
}
