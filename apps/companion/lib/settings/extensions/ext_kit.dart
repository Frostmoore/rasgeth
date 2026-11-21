// G42.11 and G42.12: the few pieces Settings › Extensions and Settings › Keychain need beyond
// automation_kit.dart, as the page draws them (`SettingsKit.tsx` `Facts`, `<details>`, a password
// field, a link that opens outside): never a native checkbox, radio, select or dialog.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/colors.dart';
import '../../ui/icons.dart';

/// Tests set this: where the links go instead of the system's browser.
@visibleForTesting
Future<void> Function(String url)? debugOpenOutside;

/// Opens [url] in the system's browser (a service's page, where its key is made, its sign-in).
Future<void> openOutside(String url) async {
  final u = Uri.tryParse(url);
  if (u == null || (u.scheme != 'http' && u.scheme != 'https')) return;
  if (debugOpenOutside case final f?) return f(url);
  await launchUrl(u, mode: LaunchMode.externalApplication);
}

/// Label and value, one per line (the page's `Facts`).
class Facts extends StatelessWidget {
  const Facts({super.key, required this.rows});

  final List<(String, Widget)> rows;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(label, style: TextStyle(color: c.dim, fontSize: 13)),
                  ),
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: TextStyle(color: c.text, fontSize: 13.5, fontWeight: FontWeight.w600),
                      child: value,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A word as a fact.
Widget factText(String s) => Text(s);

/// Monospaced text that can be selected (a path, a command, an address).
class MonoText extends StatelessWidget {
  const MonoText(this.text, {super.key, this.size = 12.5});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return SelectableText(
      text,
      style: TextStyle(fontFamily: 'monospace', fontSize: size, color: c.text, height: 1.4),
    );
  }
}

/// A box of monospaced text (the page's `<pre>` and `xw-cmd`).
class CodeBox extends StatelessWidget {
  const CodeBox(this.text, {super.key, this.maxHeight = 260});

  final String text;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      margin: const EdgeInsets.only(top: 6, bottom: 8),
      decoration: BoxDecoration(
        color: c.panel2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.line),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: MonoText(text, size: 12),
      ),
    );
  }
}

/// Something to open and read (the page's `<details>`): a title with its chevron.
class Details extends StatefulWidget {
  const Details({
    super.key,
    required this.title,
    required this.child,
    this.open = false,
    this.mono = false,
  });

  final String title;
  final Widget child;
  final bool open;
  final bool mono;

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  late bool _open = widget.open;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  RgIcon(
                    _open ? RgIcons.chevronDown : RgIcons.chevronRight,
                    size: 15,
                    color: c.dim,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        fontFamily: widget.mono ? 'monospace' : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 10), child: widget.child),
        ],
      ),
    );
  }
}

/// A field whose value is a secret (a key, a password): hidden as it is typed, never kept in the
/// app after the window closes.
class SecretField extends StatefulWidget {
  const SecretField({
    super.key,
    required this.label,
    this.help,
    required this.onChanged,
    this.hint,
    this.fieldKey,
    this.obscure = true,
    this.initial = '',
    this.error,
  });

  final String label;
  final String? help;
  final ValueChanged<String> onChanged;
  final String? hint;
  final Key? fieldKey;
  final bool obscure;
  final String initial;
  final String? error;

  @override
  State<SecretField> createState() => _SecretFieldState();
}

class _SecretFieldState extends State<SecretField> {
  late final _ctl = TextEditingController(text: widget.initial);

  @override
  void didUpdateWidget(SecretField old) {
    super.didUpdateWidget(old);
    // A value made elsewhere (the generator) replaces what is typed.
    if (widget.initial != old.initial && widget.initial != _ctl.text) _ctl.text = widget.initial;
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.label,
            style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          const SizedBox(height: 6),
          TextField(
            key: widget.fieldKey,
            controller: _ctl,
            obscureText: widget.obscure,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hint,
              errorText: widget.error,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: widget.onChanged,
          ),
          if (widget.help != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                widget.help!,
                style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }
}

/// A link in words that opens outside the app.
class OutsideLink extends StatelessWidget {
  const OutsideLink({super.key, required this.label, required this.url, this.linkKey});

  final String label;
  final String url;
  final Key? linkKey;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: linkKey,
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
        onPressed: () => openOutside(url),
        icon: RgIcon(RgIcons.external, size: 15, color: c.accent),
        label: Text(label),
      ),
    );
  }
}

/// The buttons at the bottom of a window, at the right, wrapping on a phone.
class WindowActs extends StatelessWidget {
  const WindowActs({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: children,
    ),
  );
}

/// A line of text tinted as a warning (the page's `notice warn`).
class WarnLine extends StatelessWidget {
  const WarnLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.warnText.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.warnText.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: RgIcon(RgIcons.alert, size: 16, color: c.warnText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: c.text, fontSize: 13.5, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// A search field with its drawn magnifier (the page's `xw-search`, `kc-search`): no label, the
/// hint says what it searches; [value] empties it from outside (a kind chosen on a phone).
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.fieldKey,
    this.value,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final Key? fieldKey;
  final String? value;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final _ctl = TextEditingController(text: widget.value ?? '');

  @override
  void didUpdateWidget(SearchField old) {
    super.didUpdateWidget(old);
    final v = widget.value;
    if (v != null && v != _ctl.text) _ctl.text = v;
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return TextField(
      key: widget.fieldKey,
      controller: _ctl,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: RgIcon(RgIcons.search, size: 18, color: c.dim),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
