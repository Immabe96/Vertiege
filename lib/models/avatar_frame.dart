class AvatarFrame {
  final String id;
  final String name;
  final String color;
  final String? gradient;
  final String source;

  const AvatarFrame({
    required this.id,
    required this.name,
    required this.color,
    this.gradient,
    required this.source,
  });

  static const List<AvatarFrame> predefined = [
    AvatarFrame(
      id: 'tier_hustler',
      name: 'Hustler',
      color: 'FF8C42',
      source: 'shop',
    ),
    AvatarFrame(
      id: 'tier_high_roller',
      name: 'High Roller',
      color: 'C0C0C0',
      source: 'shop',
    ),
    AvatarFrame(
      id: 'tier_elite',
      name: 'Elite',
      color: 'E5E4E2',
      gradient: 'linear-gradient(135deg, #E5E4E2 0%, #B8B8B8 100%)',
      source: 'achievement',
    ),
    AvatarFrame(
      id: 'tier_old_money',
      name: 'Old Money',
      color: 'FFD700',
      gradient: 'linear-gradient(135deg, #FFD700 0%, #DAA520 100%)',
      source: 'achievement',
    ),
    AvatarFrame(
      id: 'tier_apex',
      name: 'Apex',
      color: '9B59B6',
      gradient: 'linear-gradient(135deg, #9B59B6 0%, #8E44AD 50%, #6C3483 100%)',
      source: 'achievement',
    ),
    AvatarFrame(
      id: 'streak_7',
      name: 'Week Warrior',
      color: 'FF4500',
      source: 'achievement',
    ),
    AvatarFrame(
      id: 'streak_30',
      name: 'Month Master',
      color: 'FFD700',
      gradient: 'linear-gradient(135deg, #FFD700 0%, #FF8C00 100%)',
      source: 'achievement',
    ),
    AvatarFrame(
      id: 'season_champion',
      name: 'Season Champion',
      color: '00CED1',
      gradient: 'linear-gradient(135deg, #00CED1 0%, #20B2AA 50%, #3CB371 100%)',
      source: 'season',
    ),
  ];

  static AvatarFrame? getById(String id) {
    return predefined.firstWhere(
      (f) => f.id == id,
      orElse: () => predefined.first,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    if (gradient != null) 'gradient': gradient,
    'source': source,
  };

  static AvatarFrame fromJson(Map<String, dynamic> json) => AvatarFrame(
    id: json['id'] as String,
    name: json['name'] as String,
    color: json['color'] as String,
    gradient: json['gradient'] as String?,
    source: json['source'] as String,
  );
}
