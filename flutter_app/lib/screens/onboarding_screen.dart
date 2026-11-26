import 'package:flutter/material.dart';

import '../l10n/app_lang.dart';
import '../theme/app_theme.dart';
import '../widgets/design_kit.dart';

/// The three intro slides shown the first time the app is opened.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  /// Called when the person taps Skip or Get started on the last slide.
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  const _Slide(this.image, this.title, this.body);
  final String image;
  final String title;
  final String body;
}

const _slides = [
  _Slide(
    'assets/images/onboarding_scan.png',
    'Scan & Check Crop Leaves',
    'Snap a photo of any plant leaf to get instant AI-assisted health insights and helpful next steps.',
  ),
  _Slide(
    'assets/images/onboarding_market.png',
    'Daily Mandi Rates & Tips',
    'Check updated local market prices and find the right crops for your soil, season, and water.',
  ),
  _Slide(
    'assets/images/onboarding_sell.png',
    'Direct Farm to Buyer Selling',
    'List your fresh harvest in seconds and connect directly with buyers without middlemen.',
  ),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _slides.length - 1) {
      widget.onDone();
    } else {
      _pages.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context) {
        final last = _index == _slides.length - 1;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _slides.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _index ? 28 : 12,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? Colors.black
                              : Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: widget.onDone,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.mutedText,
                        ),
                        child: Text(tr('Skip').toUpperCase()),
                      ),
                      FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: Text(
                          (last ? tr('Get started') : tr('Next')).toUpperCase(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final topHeight = box.maxHeight * 0.45;
        final imageWidth = (box.maxWidth * 0.7).clamp(160.0, 340.0).toDouble();
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Column(
              children: [
                ClipPath(
                  clipper: _WaveClipper(),
                  child: Container(
                    height: topHeight,
                    width: double.infinity,
                    color: AppColors.primary,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(top: 24, bottom: 24),
                    child: Image.asset(
                      slide.image,
                      width: imageWidth,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        tr(slide.title),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr(slide.body),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.05,
        size.width,
        size.height * 0.7,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
