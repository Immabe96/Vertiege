import 'dart:math';

String generateId() {
  final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final rand = Random().nextInt(9999999).toString().padLeft(7, '0');
  return '$ts$rand';
}
