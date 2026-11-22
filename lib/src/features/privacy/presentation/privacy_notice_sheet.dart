import 'package:flutter/material.dart';

import '../../../core/l10n/community_localizations.dart';
import '../../../core/theme/community_tokens.dart';
import '../../../core/theme/refresh_style.dart';
import '../../../core/widgets/community_popups.dart';
import '../../../core/widgets/refresh_buttons.dart';

/// The GDPR privacy notice, full height.
///
/// Without [anonId] the user is asked: decline closes with false, agree
/// with true. With [anonId] the user already agreed, so it only shows the
/// ID and a close button.
class PrivacyNoticeSheet extends StatelessWidget {
  const PrivacyNoticeSheet({
    super.key,
    this.anonId,
    this.onOpenPrivacyPolicy,
  });

  /// The line above the buttons that shows while more text is below.
  @visibleForTesting
  static const moreBelowKey = ValueKey('community_privacy_more_below');

  final String? anonId;

  /// Opens the full Privacy Policy. Null hides the sentence with the link.
  final VoidCallback? onOpenPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final body = RefreshTokens.body(context)?.copyWith(height: CommunityTokens.readingLineHeight);
    final bold = body?.copyWith(fontWeight: FontWeight.w700);
    final anonId = this.anonId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(_side, 4, _side, 16),
          child: Text(
            l.privacyNotice,
            textAlign: TextAlign.center,
            style: RefreshTokens.title(context)?.copyWith(height: CommunityTokens.lineHeight),
          ),
        ),
        Expanded(
          child: _ScrollHint(
            padding: const EdgeInsets.fromLTRB(_side, 0, _side, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.privacyIntro, style: body),
                _gap,
                _headed(l.privacyWhyTitle, l.privacyWhyBody, bold, body),
                _gap,
                Text(l.privacyWhatTitle, style: bold),
                _Bullet(text: l.privacyUnlink, style: body),
                _Bullet(text: l.privacyDelete, style: body),
                _gap,
                _headed(l.privacyRetentionTitle, l.privacyRetentionBody, bold, body),
                _gap,
                _headed(l.privacyRightsTitle, l.privacyRightsBody, bold, body),
                if (onOpenPrivacyPolicy case final open?)
                  _PolicySentence(onOpen: open, style: body, linkStyle: bold),
                if (anonId != null) ...[
                  _gap,
                  SelectableText(
                    l.yourId(anonId),
                    style: RefreshTokens.meta(context, on: RefreshColors.sheet(context)),
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(_side, 16, _side, _side),
            // Decline (red) and Agree (filled) on a two-column grid, as on
            // Settings-18 (decline left); stacked when a label doesn't fit.
            child: anonId == null
                ? RefreshButtonPair(
                    start: RefreshButton(
                      label: l.decline,
                      kind: RefreshButtonKind.destructive,
                      onPressed: () => closePopup(context, false),
                    ),
                    end: RefreshButton(label: l.agree, onPressed: () => closePopup(context, true)),
                  )
                : RefreshButton(
                    label: l.close,
                    kind: RefreshButtonKind.secondary,
                    onPressed: () => closePopup(context),
                  ),
          ),
        ),
      ],
    );
  }

  /// The sheet's padding at the sides and the bottom.
  static const _side = RefreshTokens.sheetPadding;

  static const _gap = SizedBox(height: 16);

  static Widget _headed(String title, String text, TextStyle? bold, TextStyle? body) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$title ', style: bold),
          TextSpan(text: text, style: body),
        ],
      ),
    );
  }
}

/// Scrolls [child] with a scrollbar that is always visible, and draws a
/// line under it while more text is below, so cut-off text above the
/// buttons doesn't look like the end of the notice.
class _ScrollHint extends StatefulWidget {
  const _ScrollHint({required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  State<_ScrollHint> createState() => _ScrollHintState();
}

class _ScrollHintState extends State<_ScrollHint> {
  final _controller = ScrollController();
  final _moreBelow = ValueNotifier(false);

  @override
  void dispose() {
    _controller.dispose();
    _moreBelow.dispose();
    super.dispose();
  }

  // ScrollMetricsNotification arrives after the first layout and whenever
  // the content size changes; ScrollNotification on every scroll.
  bool _update(ScrollMetrics metrics) {
    _moreBelow.value = metrics.extentAfter > 0;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (n) => _update(n.metrics),
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) => _update(n.metrics),
              child: Scrollbar(
                controller: _controller,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _controller,
                  padding: widget.padding,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _moreBelow,
          builder: (context, moreBelow, _) => AnimatedOpacity(
            key: PrivacyNoticeSheet.moreBelowKey,
            opacity: moreBelow ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: Divider(height: 1, thickness: 1, color: RefreshColors.faintBorder(context)),
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 16, child: Text('•', style: style)),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

/// "Read our full Privacy Policy for details." with the link in the middle.
class _PolicySentence extends StatelessWidget {
  const _PolicySentence({required this.onOpen, required this.style, required this.linkStyle});

  final VoidCallback onOpen;
  final TextStyle? style;
  final TextStyle? linkStyle;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final primary = RefreshColors.readable(scheme.primary, scheme.onSurface, RefreshColors.sheet(context), 4.5);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: l.privacyPolicyBefore),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Semantics(
              link: true,
              child: InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(RefreshTokens.controlRadius),
                child: Text(l.privacyPolicyLink, style: linkStyle?.copyWith(color: primary)),
              ),
            ),
          ),
          TextSpan(text: l.privacyPolicyAfter),
        ],
      ),
    );
  }
}
