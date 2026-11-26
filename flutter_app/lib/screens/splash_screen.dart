import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The green start screen with the logo and the app name.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', width: 84, height: 84),
              const SizedBox(width: 16),
              const Flexible(
                child: Text(
                  'FasalMitra',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFDBE8DD),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
