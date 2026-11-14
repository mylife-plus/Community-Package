import 'package:flutter/material.dart';

import 'community_tokens.dart';

const _lineHeight = TextStyle(
  height: CommunityTokens.lineHeight,
  leadingDistribution: TextLeadingDistribution.even,
);

const _lineHeights = TextTheme(
  displayLarge: _lineHeight,
  displayMedium: _lineHeight,
  displaySmall: _lineHeight,
  headlineLarge: _lineHeight,
  headlineMedium: _lineHeight,
  headlineSmall: _lineHeight,
  titleLarge: _lineHeight,
  titleMedium: _lineHeight,
  titleSmall: _lineHeight,
  bodyLarge: _lineHeight,
  bodyMedium: _lineHeight,
  bodySmall: _lineHeight,
  labelLarge: _lineHeight,
  labelMedium: _lineHeight,
  labelSmall: _lineHeight,
);

/// The host's [base] theme with Figma's line height on every text style.
/// Font family, sizes and colours stay the host's. Sheets and popups opened
/// from package screens carry it too: showModalBottomSheet and showDialog
/// pass the caller's themes on (InheritedTheme.capture).
ThemeData communityTheme(ThemeData base) =>
    base.copyWith(textTheme: base.textTheme.merge(_lineHeights));
