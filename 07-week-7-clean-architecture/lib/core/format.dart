String formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

int? parseRouteId(String path) {
  final segments = Uri.parse(path).pathSegments;
  if (segments.isEmpty) return null;
  return int.tryParse(segments.last);
}

