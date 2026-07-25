import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/marketplace_listing.dart';

class MarketplaceService {
  MarketplaceService(this._sb);
  final SupabaseClient _sb;

  String get _uid => _sb.auth.currentUser!.id;

  /// Active listings from everyone (including your own), newest first.
  /// Uses the view so auctions come back with their current highest bid.
  Future<List<MarketplaceListing>> browse({String? category}) async {
    var query = _sb.from('marketplace_listings_with_highest_bid').select().eq('status', 'active');
    if (category != null) {
      query = query.eq('item_category', category);
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map((r) => MarketplaceListing.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<MarketplaceListing>> myListings() async {
    final rows = await _sb
        .from('marketplace_listings_with_highest_bid')
        .select()
        .eq('seller_id', _uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => MarketplaceListing.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<MarketplaceListing> create(MarketplaceListing listing) async {
    final row = await _sb
        .from('marketplace_listings')
        .insert(listing.toInsert(_uid))
        .select()
        .single();
    return MarketplaceListing.fromMap(row);
  }

  Future<void> cancel(String listingId) async {
    await _sb.from('marketplace_listings').update({'status': 'cancelled'}).eq('id', listingId);
  }

  /// Seller manually marks a fixed-price listing as sold (no payment
  /// processing in this phase — settlement happens off-app).
  Future<void> markSold(String listingId) async {
    await _sb.from('marketplace_listings').update({'status': 'sold'}).eq('id', listingId);
  }

  // Bids (auctions) -------------------------------------------------

  Future<List<MarketplaceBid>> bidsFor(String listingId) async {
    final rows = await _sb
        .from('marketplace_bids')
        .select()
        .eq('listing_id', listingId)
        .order('amount', ascending: false);
    return (rows as List).map((r) => MarketplaceBid.fromMap(r as Map<String, dynamic>)).toList();
  }

  /// Throws a PostgrestException with a readable message if the bid is
  /// rejected (too low, auction ended, bidding on your own listing, etc.) —
  /// the server-side trigger is the source of truth, this is just the call.
  Future<MarketplaceBid> placeBid(String listingId, double amount) async {
    final row = await _sb
        .from('marketplace_bids')
        .insert({'listing_id': listingId, 'bidder_id': _uid, 'amount': amount})
        .select()
        .single();
    return MarketplaceBid.fromMap(row);
  }

  // Orders (fixed-price "request to buy") ----------------------------

  Future<MarketplaceOrder> requestToBuy(String listingId, double quantity) async {
    final row = await _sb
        .from('marketplace_orders')
        .insert({'listing_id': listingId, 'buyer_id': _uid, 'quantity': quantity})
        .select()
        .single();
    return MarketplaceOrder.fromMap(row);
  }

  Future<List<MarketplaceOrder>> myPurchaseRequests() async {
    final rows = await _sb
        .from('marketplace_orders')
        .select()
        .eq('buyer_id', _uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => MarketplaceOrder.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<MarketplaceOrder>> incomingOrders() async {
    final rows = await _sb
        .from('marketplace_orders')
        .select()
        .eq('seller_id', _uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => MarketplaceOrder.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _sb.from('marketplace_orders').update({'status': status}).eq('id', orderId);
  }
}
