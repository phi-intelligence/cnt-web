import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Hamburger menu button with animated icon
class HamburgerMenuButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? color;
  final double size;

  const HamburgerMenuButton({
    super.key,
    required this.onPressed,
    this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.menu,
        size: size,
        color: color ?? AppColors.warmBrown,
      ),
      onPressed: onPressed,
      tooltip: 'Menu',
      splashRadius: 24,
    );
  }
}

/// Animated hamburger menu button (transforms to X when active)
class AnimatedHamburgerButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isActive;
  final Color? color;
  final double size;

  const AnimatedHamburgerButton({
    super.key,
    required this.onPressed,
    this.isActive = false,
    this.color,
    this.size = 24.0,
  });

  @override
  State<AnimatedHamburgerButton> createState() => _AnimatedHamburgerButtonState();
}

class _AnimatedHamburgerButtonState extends State<AnimatedHamburgerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(AnimatedHamburgerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_close,
        progress: _controller,
        size: widget.size,
        color: widget.color ?? AppColors.warmBrown,
      ),
      onPressed: widget.onPressed,
      tooltip: widget.isActive ? 'Close menu' : 'Open menu',
      splashRadius: 24,
    );
  }
}



