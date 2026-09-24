/// Subtitle for channel / world headers — online + total residents (Vertiege lexicon).
String worldChannelResidentSubtitle({
  required int totalResidents,
  int? onlineResidents,
}) {
  final total = totalResidents.clamp(0, 999999);
  final online = onlineResidents?.clamp(0, total > 0 ? total : 999999);

  if (online != null && online > 0 && total > 0) {
    final residentWord = total == 1 ? 'resident' : 'residents';
    return '$online online · $total $residentWord';
  }
  if (total == 1) return '1 resident';
  if (total > 0) return '$total residents';
  return '';
}

/// Pluralized member count for world lists (`1 member` / `N members`).
String worldMemberCountLabel(int count) {
  final n = count.clamp(0, 999999);
  return n == 1 ? '1 member' : '$n members';
}
