import 'package:flutter/material.dart';

import '../../data/models/feedback_item.dart';
import '../../data/models/feedback_query.dart';
import '../l10n/community_localizations.dart';
import '../theme/community_tokens.dart';
import '../utils/formatters.dart';
import 'community_popups.dart';
import 'emoji_text.dart';
import 'feedback_card.dart';

// The sort and filter menus of a feedback list. Not in Figma; built like the
// New Feedback topic menu (frame 1:144): surface, primary outline and
// dividers, 8 px corners, 42 px rows.

/// The sort options, the current one ticked. Choosing one closes the menu
/// with it.
class FeedbackSortMenu extends StatelessWidget {
  const FeedbackSortMenu({super.key, required this.selected});

  final FeedbackSort selected;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    return _MenuFrame(
      children: [
        for (final sort in FeedbackSort.values)
          _MenuRow(
            label: Text(feedbackSortLabel(l, sort)),
            selected: sort == selected,
            onTap: () => closePopup(context, sort),
          ),
      ],
    );
  }
}

/// Type and Progress rows to tick, and a reset row once anything is ticked.
/// Each tap applies at once and the menu stays open.
class FeedbackFilterMenu extends StatefulWidget {
  const FeedbackFilterMenu({
    super.key,
    required this.types,
    required this.statuses,
    required this.onToggleType,
    required this.onToggleStatus,
    required this.onReset,
  });

  final Set<FeedbackType> types;
  final Set<FeedbackStatus> statuses;
  final ValueChanged<FeedbackType> onToggleType;
  final ValueChanged<FeedbackStatus> onToggleStatus;
  final VoidCallback onReset;

  @override
  State<FeedbackFilterMenu> createState() => _FeedbackFilterMenuState();
}

class _FeedbackFilterMenuState extends State<FeedbackFilterMenu> {
  // The menu is its own route, so it keeps a copy of the ticks to show them
  // at once; every tap also goes to the list through the callbacks.
  late Set<FeedbackType> _types = {...widget.types};
  late Set<FeedbackStatus> _statuses = {...widget.statuses};

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final colors = CommunityColors.of(context);
    return _MenuFrame(
      children: [
        _MenuHeader(l.filterType),
        for (final type in FeedbackType.values)
          _MenuRow(
            emoji: feedbackTypeEmoji(type),
            label: Text(feedbackTypeLabel(l, type)),
            selected: _types.contains(type),
            onTap: () {
              setState(() => _types = _toggled(_types, type));
              widget.onToggleType(type);
            },
          ),
        _MenuHeader(l.filterProgress),
        for (final status in FeedbackStatus.values)
          _MenuRow(
            emoji: '💪',
            label: Text(
              feedbackStatusLabel(l, status),
              style: TextStyle(color: colors.status(status)),
            ),
            selected: _statuses.contains(status),
            onTap: () {
              setState(() => _statuses = _toggled(_statuses, status));
              widget.onToggleStatus(status);
            },
          ),
        if (_types.isNotEmpty || _statuses.isNotEmpty)
          _MenuRow(
            label: Text(l.resetFilter, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            centered: true,
            onTap: () {
              setState(() {
                _types = {};
                _statuses = {};
              });
              widget.onReset();
            },
          ),
      ],
    );
  }

  static Set<T> _toggled<T>(Set<T> values, T value) =>
      values.contains(value) ? ({...values}..remove(value)) : {...values, value};
}

/// The outlined box, with a divider between rows. Scrolls when the screen
/// is too short for it.
class _MenuFrame extends StatelessWidget {
  const _MenuFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final divider = Container(height: 1, color: scheme.primary);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: CommunityTokens.topicMenuMinWidth),
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CommunityTokens.topicRadius),
          side: BorderSide(color: scheme.primary),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) divider,
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A group title inside the filter menu.
class _MenuHeader extends StatelessWidget {
  const _MenuHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: CommunityTokens.menuHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: CommunityTokens.menuRowPadding),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CommunityColors.muted(context),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    this.emoji,
    required this.label,
    this.selected = false,
    this.centered = false,
    required this.onTap,
  });

  final String? emoji;
  final Text label;
  final bool selected;

  /// A lone action such as reset: centred, no tick.
  final bool centered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emoji = this.emoji;
    final style = theme.textTheme.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );
    return Semantics(
      selected: centered ? null : selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: CommunityTokens.topicRowHeight,
          padding: const EdgeInsets.symmetric(horizontal: CommunityTokens.menuRowPadding),
          child: Row(
            mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              if (emoji != null) ...[EmojiText(emoji, size: 16), const SizedBox(width: 6)],
              // The only flexible child, so the label gets all the room left.
              Flexible(
                fit: centered ? FlexFit.loose : FlexFit.tight,
                child: DefaultTextStyle.merge(
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: label,
                ),
              ),
              if (!centered) ...[
                const SizedBox(width: 12),
                // Space kept when not ticked, so the menu does not change width.
                SizedBox(
                  width: CommunityTokens.menuTickSize,
                  child: selected
                      ? Icon(Icons.check, size: CommunityTokens.menuTickSize, color: theme.colorScheme.primary)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
