import 'package:intl/intl.dart';

class AppUtils {
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy h:mm a').format(date);
  }

  static String formatCoordinates(double lat, double lng) {
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }
}
