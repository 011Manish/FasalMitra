class MarketplaceListing {
  final String id;
  final String sellerId;
  final String? farmId;
  final String listingType; // 'fixed_price' | 'auction'
  final String itemCategory; // 'crop' | 'seed' | 'fertilizer' | 'pesticide' | 'tool'
  final String title;
  final String? description;
  final String unit;
  final double quantity;
  final double price;
  final String currency;
  final DateTime? auctionEndAt;
  final String status; // 'active' | 'sold' | 'cancelled' | 'expired'
  final DateTime createdAt;
  final double? highestBid;
  final int? bidCount;

  MarketplaceListing({
    required this.id,
    required this.sellerId,
    this.farmId,
    required this.listingType,
    required this.itemCategory,
    required this.title,
    this.description,
    required this.unit,
    required this.quantity,
    required this.price,
    required this.currency,
    this.auctionEndAt,
    required this.status,
    required this.createdAt,
    this.highestBid,
    this.bidCount,
  });

  bool get isAuction => listingType == 'auction';

  double get currentPrice => highestBid ?? price;

  bool get auctionHasEnded =>
      isAuction && auctionEndAt != null && auctionEndAt!.isBefore(DateTime.now());

  factory MarketplaceListing.fromMap(Map<String, dynamic> row) => MarketplaceListing(
        id: row['id'] as String,
        sellerId: row['seller_id'] as String,
        farmId: row['farm_id'] as String?,
        listingType: row['listing_type'] as String,
        itemCategory: row['item_category'] as String,
        title: row['title'] as String,
        description: row['description'] as String?,
        unit: row['unit'] as String,
        quantity: (row['quantity'] as num).toDouble(),
        price: (row['price'] as num).toDouble(),
        currency: row['currency'] as String,
        auctionEndAt:
            row['auction_end_at'] == null ? null : DateTime.parse(row['auction_end_at'] as String),
        status: row['status'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        highestBid: (row['highest_bid'] as num?)?.toDouble(),
        bidCount: (row['bid_count'] as num?)?.toInt(),
      );

  Map<String, dynamic> toInsert(String sellerId) => {
        'seller_id': sellerId,
        'farm_id': farmId,
        'listing_type': listingType,
        'item_category': itemCategory,
        'title': title,
        'description': description,
        'unit': unit,
        'quantity': quantity,
        'price': price,
        'currency': currency,
        'auction_end_at': auctionEndAt?.toIso8601String(),
      };
}

class MarketplaceBid {
  final String id;
  final String listingId;
  final String bidderId;
  final double amount;
  final DateTime createdAt;

  MarketplaceBid({
    required this.id,
    required this.listingId,
    required this.bidderId,
    required this.amount,
    required this.createdAt,
  });

  factory MarketplaceBid.fromMap(Map<String, dynamic> row) => MarketplaceBid(
        id: row['id'] as String,
        listingId: row['listing_id'] as String,
        bidderId: row['bidder_id'] as String,
        amount: (row['amount'] as num).toDouble(),
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}

class MarketplaceOrder {
  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final double quantity;
  final String status; // 'requested' | 'confirmed' | 'cancelled' | 'completed'
  final DateTime createdAt;

  MarketplaceOrder({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });

  factory MarketplaceOrder.fromMap(Map<String, dynamic> row) => MarketplaceOrder(
        id: row['id'] as String,
        listingId: row['listing_id'] as String,
        buyerId: row['buyer_id'] as String,
        sellerId: row['seller_id'] as String,
        quantity: (row['quantity'] as num).toDouble(),
        status: row['status'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}

const listingCategories = ['crop', 'seed', 'fertilizer', 'pesticide', 'tool'];
const listingCategoryLabels = {
  'crop': 'Crop produce',
  'seed': 'Seeds',
  'fertilizer': 'Fertilizer',
  'pesticide': 'Pesticide',
  'tool': 'Tools',
};
