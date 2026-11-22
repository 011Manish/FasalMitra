import 'package:flutter/material.dart';

import 'crop_guide_screen.dart';
import 'learning_academy_screen.dart';
import 'nearby_agriculture_screen.dart';
import 'price_prediction_screen.dart';
import 'shop_screen.dart';

class HomeGridScreen extends StatelessWidget {
  const HomeGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _HomeTile(
          icon: Icons.school_outlined,
          label: 'Learning Academy',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const LearningAcademyScreen(),
            ),
          ),
        ),
        _HomeTile(
          icon: Icons.location_on_outlined,
          label: 'Nearby Agriculture',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const NearbyAgricultureScreen(),
            ),
          ),
        ),
        _HomeTile(
          icon: Icons.trending_up_outlined,
          label: 'Price Prediction',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PricePredictionScreen(),
            ),
          ),
        ),
        _HomeTile(
          icon: Icons.storefront_outlined,
          label: 'Shop',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ShopScreen(),
            ),
          ),
        ),
        _HomeTile(
          icon: Icons.eco_outlined,
          label: 'Crop Guide',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CropGuideScreen(),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 42,
                color: scheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
