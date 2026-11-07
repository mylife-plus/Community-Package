import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models/feedback_item.dart';
import '../../data/models/feedback_query.dart';
import '../l10n/community_localizations.dart';
import '../theme/community_tokens.dart';
import 'community_popups.dart';
import 'feedback_query_menus.dart';

/// The row under a list's header (Figma frame 1:426): sort, filter and
/// search on the left, + on the right. Sort and filter turn the primary
/// colour while they change the list. Search turns the whole row into a
/// search field with a ✗ that closes it.
class FeedbackListToolbar extends StatelessWidget {
  const FeedbackListToolbar({
    super.key,
    required this.query,
    required this.searchOpen,
    required this.searchController,
    required this.onSort,
    required this.onToggleType,
    required this.onToggleStatus,
    required this.onResetFilter,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.maxSearchLength,
    this.onAdd,
    this.addTooltip,
  });

  final FeedbackQuery query;
  final bool searchOpen;
  final TextEditingController searchController;
  final ValueChanged<FeedbackSort> onSort;
  final ValueChanged<FeedbackType> onToggleType;
  final ValueChanged<FeedbackStatus> onToggleStatus;
  final VoidCallback onResetFilter;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchSubmitted;
  final int maxSearchLength;

  /// The + on the right. Hidden when null.
  final VoidCallback? onAdd;
  final String? addTooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: CommunityTokens.toolbarHeight,
      padding: CommunityTokens.toolbarPadding,
      child: searchOpen
          ? _SearchField(
              controller: searchController,
              maxLength: maxSearchLength,
              onChanged: onSearchChanged,
              onSubmitted: onSearchSubmitted,
              onClose: onCloseSearch,
            )
          : _buttons(context),
    );
  }

  Widget _buttons(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final onAdd = this.onAdd;
    return Row(
      children: [
        Builder(
          builder: (buttonContext) => _ToolbarButton(
            icon: 'sort',
            size: CommunityTokens.sortIconSize,
            tooltip: l.sortTooltip,
            active: query.sort != FeedbackSort.newest,
            onPressed: () => _openSort(buttonContext),
          ),
        ),
        const SizedBox(width: CommunityTokens.toolbarButtonGap),
        Builder(
          builder: (buttonContext) => _ToolbarButton(
            icon: 'filter',
            size: CommunityTokens.filterIconSize,
            tooltip: l.filterTooltip,
            active: query.hasFilter,
            onPressed: () => _openFilter(buttonContext),
          ),
        ),
        const SizedBox(width: CommunityTokens.toolbarButtonGap),
        _ToolbarButton(
          icon: 'search',
          size: CommunityTokens.searchIconSize,
          tooltip: l.searchTooltip,
          active: false,
          onPressed: onOpenSearch,
        ),
        const Spacer(),
        if (onAdd != null)
          _ToolbarButton(
            icon: 'add',
            size: const Size.square(CommunityTokens.toolbarIconSize),
            tooltip: addTooltip,
            active: false,
            onPressed: onAdd,
          ),
      ],
    );
  }

  Future<void> _openSort(BuildContext buttonContext) async {
    final sort = await showCommunityDropdown<FeedbackSort>(
      buttonContext,
      builder: (_) => FeedbackSortMenu(selected: query.sort),
    );
    if (sort != null) onSort(sort);
  }

  Future<void> _openFilter(BuildContext buttonContext) => showCommunityDropdown<void>(
    buttonContext,
    builder: (_) => FeedbackFilterMenu(
      types: query.types,
      statuses: query.statuses,
      onToggleType: onToggleType,
      onToggleStatus: onToggleStatus,
      onReset: onResetFilter,
    ),
  );
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.size,
    required this.tooltip,
    required this.active,
    required this.onPressed,
  });

  /// File name in assets/icons, without `.svg`.
  final String icon;
  final Size size;
  final String? tooltip;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = active ? Theme.of(context).colorScheme.primary : CommunityColors.muted(context);
    return Semantics(
      selected: active,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: SvgPicture.asset(
          'assets/icons/$icon.svg',
          package: 'community_package',
          width: size.width,
          height: size.height,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}

/// One-line search field in the toolbar, with the search icon before the
/// text and a ✗ after it.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.maxLength,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClose,
  });

  final TextEditingController controller;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = CommunityColors.muted(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(CommunityTokens.fieldRadius),
      borderSide: BorderSide(color: color),
    );

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            onSubmitted: (_) => onSubmitted(),
            // A limit without the counter under the field.
            inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface,
            ),
            // Every part of the decoration is set, so a host's
            // InputDecorationTheme cannot add a second box (as Inventory's
            // did inside the Problem steps, S4).
            decoration: InputDecoration(
              hintText: l.searchHint,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: muted,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              isDense: true,
              contentPadding: CommunityTokens.searchFieldPadding,
              constraints: const BoxConstraints.tightFor(height: CommunityTokens.searchFieldHeight),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SvgPicture.asset(
                  'assets/icons/search.svg',
                  package: 'community_package',
                  width: 16,
                  height: 17,
                  colorFilter: ColorFilter.mode(muted, BlendMode.srcIn),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(),
              border: border(CommunityColors.fieldBorder(context)),
              enabledBorder: border(CommunityColors.fieldBorder(context)),
              focusedBorder: border(theme.colorScheme.primary),
              disabledBorder: border(CommunityColors.fieldBorder(context)),
            ),
          ),
        ),
        IconButton(
          tooltip: l.closeSearch,
          onPressed: onClose,
          icon: Icon(Icons.close, size: 24, color: muted),
        ),
      ],
    );
  }
}
