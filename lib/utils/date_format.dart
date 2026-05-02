String formatTimestamp(int ts) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final diff = now - ts;

  if (diff < 60000) return 'Just now';
  if (diff < 3600000) return '${diff ~/ 60000}m ago';
  if (diff < 86400000) return '${diff ~/ 3600000}h ago';
  return '${diff ~/ 86400000}d ago';
}
