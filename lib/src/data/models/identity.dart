import 'package:freezed_annotation/freezed_annotation.dart';

part 'identity.freezed.dart';

/// What the user has agreed to on this phone.
@freezed
abstract class Identity with _$Identity {
  const factory Identity({
    /// Exists only after the user agreed to the privacy notice.
    String? anonId,

    /// Agreed to the community rules. Asked once, before the first post.
    @Default(false) bool rulesAgreed,
  }) = _Identity;

  const Identity._();

  bool get agreedToPrivacy => anonId != null;
}
