import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Password field tuned for Flutter Web's dual canvas + HTML input rendering.
///
/// The HTML input layer only captures keystrokes; visible text is always painted
/// on the Flutter canvas (see index.html — native input text is transparent).
class WebSafePasswordField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final TextStyle? style;
  final String? Function(String?)? validator;
  final bool initiallyObscured;
  final Color toggleIconColor;

  const WebSafePasswordField({
    super.key,
    required this.controller,
    required this.decoration,
    this.style,
    this.validator,
    this.initiallyObscured = true,
    this.toggleIconColor = Colors.grey,
  });

  @override
  State<WebSafePasswordField> createState() => _WebSafePasswordFieldState();
}

class _WebSafePasswordFieldState extends State<WebSafePasswordField> {
  static const Color _fallbackTextColor = Color(0xFF2D2520);

  late bool _obscurePassword;

  @override
  void initState() {
    super.initState();
    _obscurePassword = widget.initiallyObscured;
  }

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

  void _toggleObscured() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    final decoration = widget.decoration;
    final fieldStyle = _resolveStyle();

    return TextFormField(
      key: kIsWeb ? ValueKey('web-password-$_obscurePassword') : null,
      controller: widget.controller,
      obscureText: _obscurePassword,
      autocorrect: false,
      enableSuggestions: false,
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
      decoration: decoration.copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: widget.toggleIconColor,
          ),
          onPressed: _toggleObscured,
        ),
      ),
    );
  }
}
