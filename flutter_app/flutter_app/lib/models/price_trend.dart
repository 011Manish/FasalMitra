import 'crop_price_point.dart';

enum TrendDirection { up, down, stable }

class PriceTrend {
  PriceTrend({
    required this.points,
    required this.percentChange,
    required this.direction,
    required this.nextEstimate,
  });

  final List<CropPricePoint> points;
  final double percentChange;
  final TrendDirection direction;
  final double nextEstimate;

  String get sellHint {
    switch (direction) {
      case TrendDirection.up:
        return 'Prices have risen ${percentChange.abs().toStringAsFixed(0)}% recently — consider selling soon.';
      case TrendDirection.down:
        return 'Prices have dropped ${percentChange.abs().toStringAsFixed(0)}% recently — you may want to wait if you can.';
      case TrendDirection.stable:
        return 'Prices have been stable recently.';
    }
  }

  factory PriceTrend.fromPoints(List<CropPricePoint> points) {
    if (points.length < 2) {
      final only = points.isEmpty ? 0.0 : points.first.avgPrice;
      return PriceTrend(
        points: points,
        percentChange: 0,
        direction: TrendDirection.stable,
        nextEstimate: only,
      );
    }
    final first = points.first.avgPrice;
    final last = points.last.avgPrice;
    final change = first == 0 ? 0.0 : ((last - first) / first) * 100;
    final direction = change > 3
        ? TrendDirection.up
        : change < -3
            ? TrendDirection.down
            : TrendDirection.stable;
    final recentSlope =
        (points.last.avgPrice - points[points.length - 2].avgPrice);
    return PriceTrend(
      points: points,
      percentChange: change,
      direction: direction,
      nextEstimate: last + recentSlope,
    );
  }
}
