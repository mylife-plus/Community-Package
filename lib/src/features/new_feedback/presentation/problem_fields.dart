import 'package:flutter/material.dart';

import '../../../core/identity/device_details.dart';
import '../../../core/l10n/community_localizations.dart';
import '../../../core/theme/community_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/community_text_field.dart';
import '../../../core/widgets/emoji_text.dart';
import '../domain/screen_tree.dart';
import 'new_feedback_controller.dart';

/// "📲 select a screen", or the chosen screen's path. Tapping it opens the
/// screen picker.
class ScreenPickerField extends StatelessWidget {
  const ScreenPickerField({super.key, required this.screen, required this.onTap});

  final ScreenChoice? screen;

  /// Null while the form is locked.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    final chosen = screen;
    final style = theme.textTheme.bodyLarge?.copyWith(
      fontSize: 20,
      fontWeight: chosen == null ? FontWeight.w300 : FontWeight.w400,
      color: chosen == null ? CommunityColors.muted(context) : theme.colorScheme.onSurface,
    );
    final radius = BorderRadius.circular(CommunityTokens.fieldRadius);

    return Semantics(
      button: true,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: CommunityColors.fieldBorder(context)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: CommunityTokens.fieldMinHeight),
            child: Padding(
              padding: CommunityTokens.fieldPadding,
              child: Row(
                children: [
                  const EmojiText('📲', size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      chosen == null ? l.selectScreen : formatScreenNames(chosen.path),
                      style: style,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One step to reproduce: its number in the theme's primary colour, always
/// shown before the text so nobody types it themselves, then the field.
/// Enter moves on to the next step.
class ProblemStepField extends StatefulWidget {
  const ProblemStepField({
    super.key,
    required this.number,
    required this.initialText,
    required this.enabled,
    required this.onChanged,
    required this.onLeave,
  });

  final int number;
  final String initialText;
  final bool enabled;
  final ValueChanged<String> onChanged;

  /// The field lost focus.
  final VoidCallback onLeave;

  @override
  State<ProblemStepField> createState() => _ProblemStepFieldState();
}

class _ProblemStepFieldState extends State<ProblemStepField> {
  late final _text = TextEditingController(text: widget.initialText);
  final _focus = FocusNode();
  late bool _filled = widget.initialText.isNotEmpty;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _text.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focus.hasFocus != _focused) setState(() => _focused = _focus.hasFocus);
    if (!_focus.hasFocus) widget.onLeave();
  }

  void _onChanged(String text) {
    if (text.isNotEmpty != _filled) setState(() => _filled = text.isNotEmpty);
    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    final theme = Theme.of(context);
    final textStyle = CommunityTextField.textStyle(context);
    final padding = CommunityTokens.fieldPadding;

    // The number sits outside the TextField: a prefix inside it (prefixText)
    // shows only while the field is focused or filled (input_decorator.dart,
    // _labelShouldWithdraw), and Flutter 3.29 has no widget hint to colour
    // it in. Its own bordered box keeps it visible and on the first line.
    return Container(
      constraints: const BoxConstraints(minHeight: CommunityTokens.fieldMinHeight),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: padding.left),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: _focused ? theme.colorScheme.primary : CommunityColors.fieldBorder(context),
        ),
        borderRadius: BorderRadius.circular(CommunityTokens.fieldRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('${widget.number}.', style: textStyle?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _text,
              focusNode: _focus,
              onChanged: _onChanged,
              enabled: widget.enabled,
              maxLength: NewFeedbackController.maxStepLength,
              buildCounter: CommunityTextField.counter,
              minLines: 1,
              maxLines: CommunityTextField.maxLines,
              // Wraps long steps; Enter moves on instead of a new line.
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              style: textStyle,
              decoration: InputDecoration(
                // The hint goes once there is text. Flutter keeps a hidden
                // hint's height (input_decorator.dart: `decoration.isEmpty ||
                // decoration.maintainHintSize ? hintSize.height : 0.0`), so a
                // hint that wraps made a one-line step two lines tall. The
                // flag that turns this off is maintainHintHeight in Flutter
                // 3.29 and maintainHintSize from 3.30, so no single name works
                // across the supported versions.
                hintText: _filled ? null : l.stepHint,
                hintStyle: CommunityTextField.hintStyle(context),
                // The box around the number draws the field. Without these
                // the host's input theme (fill, borders, min size) would
                // draw a second box inside it.
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                constraints: const BoxConstraints(),
                isDense: true,
                contentPadding: EdgeInsets.fromLTRB(0, padding.top, padding.right, padding.bottom),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// OS, app version and phone model, filled in by the package and read-only.
/// Empty while they are read; a detail that could not be read shows "–".
class DeviceDetailsRow extends StatelessWidget {
  const DeviceDetailsRow({super.key, required this.details});

  /// Null while they are read.
  final DeviceDetails? details;

  @override
  Widget build(BuildContext context) {
    final l = CommunityLocalizations.of(context);
    String value(String? Function(DeviceDetails d) pick) {
      final d = details;
      if (d == null) return '';
      return pick(d) ?? '–';
    }

    const flex = CommunityTokens.deviceBoxFlex;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: flex.os,
          child: _DeviceBox(label: l.deviceOs, value: value((d) => d.osVersion)),
        ),
        const SizedBox(width: CommunityTokens.deviceBoxGap),
        Expanded(
          flex: flex.app,
          child: _DeviceBox(label: l.deviceApp, value: value((d) => d.appVersion)),
        ),
        const SizedBox(width: CommunityTokens.deviceBoxGap),
        Expanded(
          flex: flex.phone,
          child: _DeviceBox(label: l.devicePhone, value: value((d) => d.deviceModel)),
        ),
      ],
    );
  }
}

class _DeviceBox extends StatelessWidget {
  const _DeviceBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label $value',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: CommunityTokens.fieldMinHeight),
        padding: CommunityTokens.deviceBoxPadding,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: CommunityColors.fieldBorder(context)),
          borderRadius: BorderRadius.circular(CommunityTokens.fieldRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.2,
                color: CommunityColors.muted(context),
              ),
            ),
            // Long values shrink to fit instead of being cut off.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
