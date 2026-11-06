import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Gives a screen its own controller for as long as the screen is mounted.
///
/// The package has no GetX routing, so nothing would remove controllers on
/// its own. The scope registers the controller under a unique `community_`
/// tag (so it can never clash with a host app's GetX registrations) and
/// deletes it, which runs `onClose`, when the screen goes away.
class ControllerScope<T extends GetxController> extends StatefulWidget {
  const ControllerScope({super.key, required this.create, required this.builder});

  final T Function() create;
  final Widget Function(T controller) builder;

  @override
  State<ControllerScope<T>> createState() => _ControllerScopeState<T>();
}

class _ControllerScopeState<T extends GetxController> extends State<ControllerScope<T>> {
  late final String _tag = 'community_${T}_${identityHashCode(this)}';

  @override
  void initState() {
    super.initState();
    Get.put<T>(widget.create(), tag: _tag);
  }

  @override
  void dispose() {
    Get.delete<T>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GetBuilder<T>(tag: _tag, builder: widget.builder);
}
