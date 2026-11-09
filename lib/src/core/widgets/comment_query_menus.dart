import 'package:flutter/material.dart';

import '../../data/models/comment_query.dart';
import '../l10n/community_localizations.dart';
import '../utils/formatters.dart';
import 'community_menu.dart';
import 'community_popups.dart';

// The sort and filter menus of a feedback's comments (community_menu.dart).

/// The comment sort options, the current one ticked. Choosing one closes
/// the menu with it.
class CommentSortMenu extends StatelessWidget {
  const CommentSortMenu({super.key, required this.selected});

  final CommentSort selected;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    return CommunityMenuFrame(
      children: [
        for (final sort in CommentSort.values)
          CommunityMenuRow(
            label: Text(commentSortLabel(l, sort)),
            selected: sort == selected,
            onTap: () => closePopup(context, sort),
          ),
      ],
    );
  }
}

/// Mine and Admin rows to tick, and a reset row once one is ticked. Each
/// tap applies at once and the menu stays open.
class CommentFilterMenu extends StatefulWidget {
  const CommentFilterMenu({
    super.key,
    required this.filters,
    required this.onToggle,
    required this.onReset,
  });

  final Set<CommentFilter> filters;
  final ValueChanged<CommentFilter> onToggle;
  final VoidCallback onReset;

  @override
  State<CommentFilterMenu> createState() => _CommentFilterMenuState();
}

class _CommentFilterMenuState extends State<CommentFilterMenu> {
  // The menu is its own route, so it keeps a copy of the ticks to show them
  // at once; every tap also goes to the screen through the callbacks.
  late Set<CommentFilter> _filters = {...widget.filters};

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    return CommunityMenuFrame(
      children: [
        for (final filter in CommentFilter.values)
          CommunityMenuRow(
            label: Text(commentFilterLabel(l, filter)),
            selected: _filters.contains(filter),
            onTap: () {
              setState(() {
                _filters = _filters.contains(filter)
                    ? ({..._filters}..remove(filter))
                    : {..._filters, filter};
              });
              widget.onToggle(filter);
            },
          ),
        if (_filters.isNotEmpty)
          CommunityMenuRow(
            label: Text(l.resetFilter, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            centered: true,
            onTap: () {
              setState(() => _filters = {});
              widget.onReset();
            },
          ),
      ],
    );
  }
}

/// Opens [CommentSortMenu] under the button [anchor] belongs to and passes
/// the chosen order to [onSelected].
Future<void> showCommentSortMenu(
  BuildContext anchor, {
  required CommentSort selected,
  required ValueChanged<CommentSort> onSelected,
}) async {
  final sort = await showCommunityDropdown<CommentSort>(
    anchor,
    builder: (_) => CommentSortMenu(selected: selected),
  );
  if (sort != null) onSelected(sort);
}

/// Opens [CommentFilterMenu] under the button [anchor] belongs to.
Future<void> showCommentFilterMenu(
  BuildContext anchor, {
  required Set<CommentFilter> filters,
  required ValueChanged<CommentFilter> onToggle,
  required VoidCallback onReset,
}) => showCommunityDropdown<void>(
  anchor,
  builder: (_) => CommentFilterMenu(filters: filters, onToggle: onToggle, onReset: onReset),
);
