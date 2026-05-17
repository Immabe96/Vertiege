enum ListingStatus { active, sold, cancelled }
enum ListingCategory { general, cosmetics, services, resources, accounts, other }

class Listing {
  final String id;
  final String worldId;
  final String sellerId;
  final String sellerName;
  final String title;
  final String description;
  final String? price;
  final String? priceNote;
  final ListingCategory category;
  final String? imageUrl;
  final ListingStatus status;
  final DateTime createdAt;

  const Listing({
    required this.id,
    required this.worldId,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    this.price,
    this.priceNote,
    required this.category,
    this.imageUrl,
    this.status = ListingStatus.active,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'world_id': worldId,
    'seller_id': sellerId,
    'seller_name': sellerName,
    'title': title,
    'description': description,
    if (price != null) 'price': price,
    if (priceNote != null) 'price_note': priceNote,
    'category': category.name,
    if (imageUrl != null) 'image_url': imageUrl,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
    id: json['id'] ?? '',
    worldId: json['world_id'] ?? '',
    sellerId: json['seller_id'] ?? '',
    sellerName: json['seller_name'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    price: json['price'],
    priceNote: json['price_note'],
    category: _parseCategory(json['category']),
    imageUrl: json['image_url'],
    status: _parseStatus(json['status']),
    createdAt: _parseDate(json['created_at']),
  );

  static Listing fromSupabase(Map<String, dynamic> data) => Listing(
    id: data['id'] ?? '',
    worldId: data['world_id'] ?? '',
    sellerId: data['seller_id'] ?? '',
    sellerName: data['seller_name'] ?? '',
    title: data['title'] ?? '',
    description: data['description'] ?? '',
    price: data['price'],
    priceNote: data['price_note'],
    category: _parseCategory(data['category']),
    imageUrl: data['image_url'],
    status: _parseStatus(data['status']),
    createdAt: _parseDate(data['created_at']),
  );

  Listing copyWith({
    String? id,
    String? worldId,
    String? sellerId,
    String? sellerName,
    String? title,
    String? description,
    String? price,
    String? priceNote,
    ListingCategory? category,
    String? imageUrl,
    ListingStatus? status,
    DateTime? createdAt,
  }) => Listing(
    id: id ?? this.id,
    worldId: worldId ?? this.worldId,
    sellerId: sellerId ?? this.sellerId,
    sellerName: sellerName ?? this.sellerName,
    title: title ?? this.title,
    description: description ?? this.description,
    price: price ?? this.price,
    priceNote: priceNote ?? this.priceNote,
    category: category ?? this.category,
    imageUrl: imageUrl ?? this.imageUrl,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );

  static ListingCategory _parseCategory(String? raw) {
    return ListingCategory.values.firstWhere(
      (c) => c.name == raw,
      orElse: () => ListingCategory.general,
    );
  }

  static ListingStatus _parseStatus(String? raw) {
    return ListingStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => ListingStatus.active,
    );
  }

  static DateTime _parseDate(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
