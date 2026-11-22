import 'package:flutter/material.dart';

import '../../data/models/feedback_item.dart';
import '../../data/models/feedback_query.dart';
import '../l10n/community_localizations.dart';
import '../theme/community_tokens.dart';
import '../utils/formatters.dart';
import 'community_menu.dart';
import 'community_popups.dart';
import 'feedback_card.dart';

// The sort and filter menus of a feedback list (community_menu.dart).

/// The sort options, the current one ticked. Choosing one closes the menu
/// with it.
class FeedbackSortMenu extends StatelessWidget {
  const FeedbackSortMenu({super.key, required this.selected});

  final FeedbackSort selected;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    return CommunityMenuFrame(
      children: [
        for (final sort in FeedbackSort.values)
          CommunityMenuRow(
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
    return CommunityMenuFrame(
      children: [
        CommunityMenuHeader(l.filterType),
        for (final type in FeedbackType.values)
          CommunityMenuRow(
            emoji: feedbackTypeEmoji(type),
            label: Text(feedbackTypeLabel(l, type)),
            selected: _types.contains(type),
            onTap: () {
              setState(() => _types = _toggled(_types, type));
              widget.onToggleType(type);
            },
          ),
        CommunityMenuHeader(l.filterProgress),
        for (final status in FeedbackStatus.values)
          CommunityMenuRow(
            emoji: '💪',
            label: Text(
              feedbackStatusLabel(l, status),
              style: TextStyle(color: CommunityMenuFrame.readable(context, colors.status(status))),
            ),
            selected: _statuses.contains(status),
            onTap: () {
              setState(() => _statuses = _toggled(_statuses, status));
              widget.onToggleStatus(status);
            },
          ),
        if (_types.isNotEmpty || _statuses.isNotEmpty)
          CommunityMenuRow(
            label: Text(l.resetFilter, style: TextStyle(color: CommunityMenuFrame.readable(context, Theme.of(context).colorScheme.primary))),
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

/// Opens [FeedbackSortMenu] under the button [anchor] belongs to and passes
/// the chosen order to [onSelected].
Future<void> showFeedbackSortMenu(
  BuildContext anchor, {
  required FeedbackSort selected,
  required ValueChanged<FeedbackSort> onSelected,
}) async {
  final sort = await showCommunityDropdown<FeedbackSort>(
    anchor,
    builder: (_) => FeedbackSortMenu(selected: selected),
  );
  if (sort != null) onSelected(sort);
}

/// Opens [FeedbackFilterMenu] under the button [anchor] belongs to.
Future<void> showFeedbackFilterMenu(
  BuildContext anchor, {
  required Set<FeedbackType> types,
  required Set<FeedbackStatus> statuses,
  required ValueChanged<FeedbackType> onToggleType,
  required ValueChanged<FeedbackStatus> onToggleStatus,
  required VoidCallback onReset,
}) => showCommunityDropdown<void>(
  anchor,
  builder: (_) => FeedbackFilterMenu(
    types: types,
    statuses: statuses,
    onToggleType: onToggleType,
    onToggleStatus: onToggleStatus,
    onReset: onReset,
  ),
);
