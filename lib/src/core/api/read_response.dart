import 'package:flutter/foundation.dart';

import '../errors/app_error.dart';

/// Reads a backend response with [parse]. A shape the app doesn't know
/// becomes an [AppError], like any other failure. [what] names the
/// response in the log.
T readResponse<T>(T Function() parse, {required String what}) {
  try {
    return parse();
  } on Object catch (e) {
    // TypeError from a cast, FormatException from a date: both are a
    // response this version can't read.
    debugPrint('community: unreadable $what response: $e');
    throw const AppError(AppErrorType.network, message: 'Unreadable response');
  }
}
