import 'package:community_package/src/core/errors/app_error.dart';
import 'package:community_package/src/core/l10n/community_localizations_de.dart';
import 'package:community_package/src/core/l10n/community_localizations_en.dart';
import 'package:community_package/src/core/l10n/community_localizations_es.dart';
import 'package:community_package/src/core/l10n/community_localizations_fr.dart';
import 'package:community_package/src/core/l10n/community_localizations_pt.dart';
import 'package:community_package/src/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tooLong = AppError(
    AppErrorType.badRequest,
    code: 'bad_request',
    details: {'field': 'text', 'maxLength': 100},
  );
  const otherBadRequest = AppError(
    AppErrorType.badRequest,
    code: 'bad_request',
    details: {'field': 'text'},
  );

  for (final l in const [
    CommunityLocalizationsEn(),
    CommunityLocalizationsDe(),
    CommunityLocalizationsEs(),
    CommunityLocalizationsFr(),
    CommunityLocalizationsPt(),
  ]) {
    test(
      '${l.runtimeType}: a too long text says the limit, other bad requests stay generic',
      () {
        expect(errorMessage(l, tooLong), l.errorTooLong(100));
        expect(errorMessage(l, tooLong), contains('100'));
        expect(errorMessage(l, tooLong), isNot(l.errorGeneric));
        expect(errorMessage(l, otherBadRequest), l.errorGeneric);
      },
    );
  }

  test('reads maxLength from the backend error body', () {
    final error = AppError.fromResponse(400, {
      'error': {
        'code': 'bad_request',
        'message': 'Text must be 1 to 100 characters',
        'details': {'field': 'text', 'maxLength': 100},
      },
    });
    expect(
      errorMessage(const CommunityLocalizationsEn(), error),
      'Too long. Use at most 100 characters.',
    );
  });
}
