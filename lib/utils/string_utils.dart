String capitalize(String str) {
  if (str.isEmpty) return str;
  return str[0].toUpperCase() + str.substring(1).toLowerCase();
}

String truncate(String str, int maxLength) {
  if (str.length <= maxLength) return str;
  return '${str.substring(0, maxLength - 3)}...';
}
