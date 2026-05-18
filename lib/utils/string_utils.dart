String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

String truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  if (maxLength <= 0) return '';
  if (maxLength == 1) return '.';
  if (maxLength == 2) return '..';
  return '${text.substring(0, maxLength - 3)}...';
}
