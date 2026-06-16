import 'package:flutter/material.dart';

/// Text field tuned for Flutter Web's dual canvas + HTML input rendering.
///
/// The HTML input layer only captures keystrokes; visible text is always painted
/// on the Flutter canvas (see index.html — native input text is transparent).
class WebSafeTextField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final TextStyle? style;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const WebSafeTextField({
    super.key,
    required this.controller,
    required this.decoration,
    this.style,
    this.validator,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  State<WebSafeTextField> createState() => _WebSafeTextFieldState();
}

class _WebSafeTextFieldState extends State<WebSafeTextField> {
  static const Color _fallbackTextColor = Color(0xFF2D2520);

  TextStyle _resolveStyle() {
    final base = widget.style ?? const TextStyle();
    final color = base.color ?? _fallbackTextColor;
    return base.copyWith(
      color: color,
      fontSize: base.fontSize ?? 16,
      height: 1.2,
      decoration: TextDecoration.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldStyle = _resolveStyle();

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      keyboardAppearance: Brightness.light,
      style: fieldStyle,
      strutStyle: StrutStyle(
        fontSize: fieldStyle.fontSize,
        height: fieldStyle.height,
        forceStrutHeight: true,
      ),
      showCursor: true,
      cursorColor: fieldStyle.color,
      cursorHeight: fieldStyle.fontSize,
      decoration: widget.decoration,
    );
  }
}
