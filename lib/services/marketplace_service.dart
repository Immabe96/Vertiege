import 'package:flutter/foundation.dart';
import '../models/listing.dart';
import 'supabase.dart';

class MarketplaceService {
  static Future<List<Listing>> getListings(
    String worldId, {
    ListingCategory? category,
    ListingStatus? status,
    int limit = 50,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    var query = client
        .from('world_listings')
        .select()
        .eq('world_id', worldId);

    if (category != null) {
      query = query.eq('category', category.name);
    }
    if (status != null) {
      query = query.eq('status', status.name);
    }

    final data = await query
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => Listing.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Listing>> getAllActiveListings({
    int limit = 50,
    int offset = 0,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('world_listings')
        .select()
        .eq('status', ListingStatus.active.name)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (data as List)
        .map((e) => Listing.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Listing?> createListing(
    String worldId,
    String title,
    String description,
    String? price,
    String? priceNote,
    ListingCategory category,
    String? imageUrl,
  ) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to create listings.');
    }
    final client = getSupabase();
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');

    final result = await client.rpc('create_listing', params: {
      'p_world_id': worldId,
      'p_title': title,
      'p_description': description,
      'p_price': price ?? '',
      'p_price_note': priceNote ?? '',
      'p_category': category.name,
      'p_image_url': imageUrl ?? '',
    });

    if (result == null) return null;
    return Listing.fromSupabase(result as Map<String, dynamic>);
  }

  static Future<bool> cancelListing(String listingId) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    try {
      await client
          .from('world_listings')
          .update({'status': ListingStatus.cancelled.name})
          .eq('id', listingId);
      return true;
    } catch (e) {
      debugPrint('MarketplaceService.cancelListing error: $e');
      return false;
    }
  }

  static Future<List<Listing>> getMyListings(String worldId) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await client
        .from('world_listings')
        .select()
        .eq('world_id', worldId)
        .eq('seller_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => Listing.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> markAsSold(String listingId) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client
        .from('world_listings')
        .update({'status': ListingStatus.sold.name})
        .eq('id', listingId);
  }
}
