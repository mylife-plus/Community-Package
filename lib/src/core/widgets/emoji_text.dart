import 'package:flutter/widgets.dart';

// Color emoji fonts: iOS first, then Android.
//
// Emoji are drawn in one of these, never in the host app's font. Flutter takes
// each character from the first font that has it and ignores the emoji
// selector U+FE0F (skbug.com/11755), so a host font with its own ❤ or ⚠ (Inter
// has both) would draw them as plain, single-colour text.
const _emojiFont = 'Apple Color Emoji';
const _emojiFallback = ['Noto Color Emoji'];

/// Text style for an emoji of [size], in the platform's color emoji font.
TextStyle emojiStyle(double size) =>
    TextStyle(fontSize: size, fontFamily: _emojiFont, fontFamilyFallback: _emojiFallback);

/// A single emoji in the platform's color emoji font.
class EmojiText extends StatelessWidget {
  const EmojiText(this.emoji, {super.key, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) => Text(emoji, style: emojiStyle(size));
}
