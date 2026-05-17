/// Award types that can be given to posts.
class AwardType {
  static const String gold = 'gold';
  static const String silver = 'silver';
  static const String helpful = 'helpful';
  static const String wholesome = 'wholesome';

  static const Map<String, AwardMeta> all = {
    gold: AwardMeta(icon: '🏆', label: 'Gold', color: 'FFD700'),
    silver: AwardMeta(icon: '🥈', label: 'Silver', color: 'C0C0C0'),
    helpful: AwardMeta(icon: '💡', label: 'Helpful', color: '42A5F5'),
    wholesome: AwardMeta(icon: '🤗', label: 'Wholesome', color: '66BB6A'),
  };
}

class AwardMeta {
  final String icon;
  final String label;
  final String color;

  const AwardMeta({
    required this.icon,
    required this.label,
    required this.color,
  });
}
