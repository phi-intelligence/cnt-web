import 'dart:math';
import 'package:flutter/material.dart';

/// Branded full-screen page background for web creation/editing flows.
///
/// Renders one of the app's hero images full-bleed (`BoxFit.cover`, so it is
/// inherently responsive) beneath a soft cream scrim. Opaque content cards
/// placed on top stay perfectly readable while the image fills the otherwise
/// empty margins, giving every page a branded, finished look.
///
/// A single image is chosen once per page instance (in [initState]) so it
/// stays stable across the many rebuilds caused by sliders, audio streams and
/// form input — it never flickers.
class PageBackground extends StatefulWidget {
  final Widget child;

  /// Force a specific asset instead of a random one.
  final String? image;

  const PageBackground({
    super.key,
    required this.child,
    this.image,
  });

  /// Atmospheric imagery shipped with the app, suitable as a backdrop.
  static const List<String> backgroundImages = [
    'assets/images/christimagenew.png',
    'assets/images/christimage.png',
    'assets/images/christnew.png',
    'assets/images/jesus-new.png',
    'assets/images/jesus2.png',
    'assets/images/jesusimg.png',
    'assets/images/jesus-teaching.png',
    'assets/images/jesus-walking.png',
    'assets/images/Jesus-crowd.png',
    'assets/images/cross.png',
  ];

  @override
  State<PageBackground> createState() => _PageBackgroundState();
}

class _PageBackgroundState extends State<PageBackground> {
  late final String _image;

  @override
  void initState() {
    super.initState();
    _image = widget.image ??
        PageBackground.backgroundImages[
            Random().nextInt(PageBackground.backgroundImages.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base fill so there is never a flash of transparency.
        const ColoredBox(color: Color(0xFFF7F5F2)),

        // Full-bleed hero image — cover keeps it responsive on any screen.
        Image.asset(
          _image,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),

        // Cream scrim for readability — lets the image read through in the
        // empty margins while keeping plenty of contrast for the cards.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xE6FAF8F5), // ~90% cream
                Color(0xD9FFFFFF), // ~85% white
                Color(0xE6F3EBE0), // ~90% warm sand
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Page content.
        Positioned.fill(child: widget.child),
      ],
    );
  }
}
