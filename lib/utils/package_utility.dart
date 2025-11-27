import 'package:intl/intl.dart';

String formatDate(DateTime? date) {
  if (date == null) {
    return 'N/A';
  }

  return DateFormat('yyyy/MM/dd').format(date);
}

/// Parses dates from the API in dd-MM-yyyy format
/// Returns null if the input is null or cannot be parsed
DateTime? parseApiDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) {
    return null;
  }

  try {
    // Try parsing dd-MM-yyyy format (e.g., "14-10-2025")
    return DateFormat('dd-MM-yyyy').parse(dateString);
  } catch (e) {
    // If that fails, try ISO format as fallback
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      print('Failed to parse date: $dateString');
      return null;
    }
  }
}
