import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/community_localizations.dart';
import '../theme/community_icons.dart';
import '../theme/community_tokens.dart';

/// The row under a list's header (Figma frames 1:426 and Settings-6): sort,
/// filter and search on the left, + on the right. Used by All Feedback and
/// by the comments of a feedback, each with its own menus.
///
/// Sort and filter turn the primary colour while they change the list.
/// Search turns the whole row into a search field with a ✗ that closes it.
class CommunityListToolbar extends StatelessWidget {
  const CommunityListToolbar({
    super.key,
    required this.sortActive,
    required this.filterActive,
    required this.onSort,
    required this.onFilter,
    required this.searchOpen,
    required this.searchController,
    required this.searchHint,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.maxSearchLength,
    this.onAdd,
    this.addTooltip,
    this.addActive = false,
  });

  /// The list is not in its default order.
  final bool sortActive;

  /// A filter narrows the list.
  final bool filterActive;

  /// Open the sort or filter menu under the button [anchor] belongs to.
  final ValueChanged<BuildContext> onSort;
  final ValueChanged<BuildContext> onFilter;

  final bool searchOpen;
  final TextEditingController searchController;
  final String searchHint;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchSubmitted;
  final int maxSearchLength;

  /// The + on the right. Hidden when null.
  final VoidCallback? onAdd;
  final String? addTooltip;

  /// The + in the primary colour, while what it opened is open.
  final bool addActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: CommunityTokens.toolbarHeight,
      padding: CommunityTokens.toolbarPadding,
      child: searchOpen
          ? _SearchField(
              controller: searchController,
              hint: searchHint,
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
            icon: CommunityIcons.sort,
            size: CommunityTokens.sortIconSize,
            tooltip: l.sortTooltip,
            active: sortActive,
            onPressed: () => onSort(buttonContext),
          ),
        ),
        const SizedBox(width: CommunityTokens.toolbarButtonGap),
        Builder(
          builder: (buttonContext) => _ToolbarButton(
            icon: CommunityIcons.filter,
            size: CommunityTokens.filterIconSize,
            tooltip: l.filterTooltip,
            active: filterActive,
            onPressed: () => onFilter(buttonContext),
          ),
        ),
        const SizedBox(width: CommunityTokens.toolbarButtonGap),
        _ToolbarButton(
          icon: CommunityIcons.search,
          size: CommunityTokens.searchIconSize,
          tooltip: l.searchTooltip,
          active: false,
          onPressed: onOpenSearch,
        ),
        const Spacer(),
        if (onAdd != null)
          _ToolbarButton(
            icon: CommunityIcons.add,
            size: const Size.square(CommunityTokens.toolbarIconSize),
            tooltip: addTooltip,
            active: addActive,
            onPressed: onAdd,
          ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.size,
    required this.tooltip,
    required this.active,
    required this.onPressed,
  });

  /// One of [CommunityIcons].
  final String icon;
  final Size size;
  final String? tooltip;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = active ? Theme.of(context).colorScheme.primary : CommunityColors.icon(context);
    return Semantics(
      selected: active,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: SvgPicture.asset(
          icon,
          package: CommunityIcons.package,
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
    required this.hint,
    required this.maxLength,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClose,
  });

  final TextEditingController controller;
  final String hint;
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
              hintText: hint,
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
                  CommunityIcons.search,
                  package: CommunityIcons.package,
                  width: 16,
                  height: 17,
                  colorFilter: ColorFilter.mode(CommunityColors.icon(context), BlendMode.srcIn),
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
          icon: Icon(Icons.close, size: 24, color: CommunityColors.icon(context)),
        ),
      ],
    );
  }
}
