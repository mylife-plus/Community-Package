import 'dart:async';
import 'dart:convert';

import 'package:community_package/src/core/api/api_client.dart';
import 'package:community_package/src/core/cache/prefs_cache.dart';
import 'package:community_package/src/data/repositories/feedback_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A scripted backend: each GET answers with the next queued response.
class FakeBackend {
  final _responses = <FutureOr<http.Response> Function(http.Request)>[];
  final requests = <http.Request>[];

  void answer(Map<String, dynamic> json) =>
      _responses.add((_) => http.Response(jsonEncode(json), 200));

  void fail({int status = 500, String code = 'server_error'}) => _responses.add(
    (_) => http.Response(jsonEncode({'error': {'code': code, 'message': 'x'}}), status),
  );

  late final http.Client client = MockClient((request) async {
    requests.add(request);
    return _responses.removeAt(0)(request);
  });

  FeedbackRepository repository({PrefsCache? cache}) => FeedbackRepository(
    ApiClient(backendUrl: 'https://example.com', appId: 'inventory', httpClient: client),
    cache ?? PrefsCache(),
  );
}
