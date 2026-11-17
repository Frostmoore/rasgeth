// A form's field as the page's `Field` (ui.tsx): its label above, the field, then the help or the
// error below, every line wrapped (a phone's window never cuts a word of it).
import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// A field that shows on any background (a window's included): the page's background inside,
/// a line around it, the accent when it has the focus.
InputDecoration fieldDecoration(RgColors c, {String? hint}) {
  OutlineInputBorder line(Color color, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: w),
  );
  return InputDecoration(
    isDense: true,
    hintText: hint,
    filled: true,
    fillColor: c.bg,
    enabledBorder: line(c.line),
    disabledBorder: line(c.line.withValues(alpha: .5)),
    focusedBorder: line(c.accent, 1.5),
    border: line(c.line),
  );
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.fieldKey,
    this.help,
    this.error,
    this.hint,
    this.secret = false,
    this.enabled = true,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final Key? fieldKey;
  final String? help;
  final String? error;
  final String? hint;
  final bool secret;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text),
          ),
          const SizedBox(height: 4),
          TextField(
            key: fieldKey,
            controller: controller,
            obscureText: secret,
            autocorrect: false,
            enableSuggestions: !secret,
            enabled: enabled,
            autofocus: autofocus,
            decoration: fieldDecoration(c, hint: hint),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(error!, style: TextStyle(fontSize: 12.5, color: c.err)),
            )
          else if (help != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(help!, style: TextStyle(fontSize: 12.5, color: c.dim, height: 1.35)),
            ),
        ],
      ),
    );
  }
}
