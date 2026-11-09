import 'package:flutter/material.dart';

import '../../../core/l10n/community_localizations.dart';
import '../../../core/theme/community_tokens.dart';
import '../../../core/widgets/community_button.dart';
import '../../../core/widgets/community_popups.dart';

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
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final body = theme.textTheme.bodyLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w300,
      color: onSurface,
    );
    final bold = body?.copyWith(fontWeight: FontWeight.w700);
    final anonId = this.anonId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(19, 24, 19, 16),
          child: Text(
            l.privacyNotice,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
        ),
        Expanded(
          child: _ScrollHint(
            padding: const EdgeInsets.fromLTRB(19, 0, 19, 16),
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
                    style: body?.copyWith(fontSize: 14, color: onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(19, 8, 19, 32),
          child: anonId == null
              // Wraps onto two lines when long labels or a large text size
              // don't fit side by side.
              ? Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CommunityButton(
                      label: l.decline,
                      destructive: true,
                      onPressed: () => closePopup(context, false),
                    ),
                    CommunityButton(label: l.agree, onPressed: () => closePopup(context, true)),
                  ],
                )
              : Center(
                  child: CommunityButton(label: l.close, onPressed: () => closePopup(context)),
                ),
        ),
      ],
    );
  }

  static const _gap = SizedBox(height: 19);

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
            child: Divider(height: 1, thickness: 1, color: CommunityColors.border(context)),
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
    final primary = Theme.of(context).colorScheme.primary;
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
                borderRadius: BorderRadius.circular(CommunityTokens.buttonRadius),
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
