// The marketing names of Rasgeth's own systems (3.10.3), as the page's `src/systems.tsx`: the name
// goes on its feature's title with a few words beside it saying what it is, in the person's
// language. The words are the page's (`sys…` in i18n.ts, through tool/general_words.mjs).
import 'package:flutter/material.dart';

import '../settings/general_words.g.dart';
import '../theme/colors.dart';

enum RgSystem { constellation, eventHorizon, nebula, deepField, filament, persistar }

String _word(BuildContext context, String key) {
  final lang = Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'it';
  return generalWords[lang]?[key] ?? generalWords['en']?[key] ?? key;
}

String _key(RgSystem s) => 'sys${s.name[0].toUpperCase()}${s.name.substring(1)}';

/// The system's name (the same in every language).
String sysName(BuildContext context, RgSystem s) => _word(context, _key(s));

/// The few words saying what it is, in the person's language.
String sysWhat(BuildContext context, RgSystem s) => _word(context, '${_key(s)}What');

/// A page word mirrored for the named systems (`wzStreamInfo1` for Deep Field).
String sysWord(BuildContext context, String key) => _word(context, key);

/// A system's name as a title, with what it is beside it (under it with [stack]).
class SysTitle extends StatelessWidget {
  const SysTitle(this.system, {super.key, this.stack = false, this.size = 15});

  final RgSystem system;
  final bool stack;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final name = Text(
      sysName(context, system),
      style: TextStyle(color: c.accent, fontWeight: FontWeight.w800, fontSize: size),
    );
    final what = Text(
      sysWhat(context, system),
      style: TextStyle(color: c.dim, fontSize: size - 2, height: 1.3),
    );
    return KeyedSubtree(
      key: Key('sys-${system.name}'),
      child: stack
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [name, what])
          : Wrap(
              spacing: 8,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [name, what],
            ),
    );
  }
}

/// A named system explained in a line, as the page's local models do (Deep Field, Persistar).
class SysExplain extends StatelessWidget {
  const SysExplain(this.system, this.text, {super.key});

  final RgSystem system;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SysTitle(system, size: 14),
          const SizedBox(height: 3),
          Text(text, style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35)),
        ],
      ),
    );
  }
}
