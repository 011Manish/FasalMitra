import 'package:flutter/material.dart';

import 'experts_list_screen.dart';
import 'finance_screen.dart';
import 'learning_academy_screen.dart';

class HomeGridScreen extends StatelessWidget {
  const HomeGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _HomeTile(
          icon: Icons.account_balance_outlined,
          label: 'Finance',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FinanceScreen()),
          ),
        ),
        _HomeTile(
          icon: Icons.school_outlined,
          label: 'Learning Academy',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LearningAcademyScreen()),
          ),
        ),
        _HomeTile(
          icon: Icons.support_agent_outlined,
          label: 'Experts',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExpertsListScreen()),
          ),
        ),
      ],
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: scheme.primary),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
