import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:community_package/src/core/api/api_client.dart';
import 'package:community_package/src/core/cache/prefs_cache.dart';
import 'package:community_package/src/data/repositories/comment_repository.dart';
import 'package:community_package/src/data/repositories/feedback_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A scripted backend: each request answers with the next queued response.
/// Answers queued for a method and path ([answerAt], [failAt]) go first, so
/// requests that run side by side can't take each other's answers.
class FakeBackend {
  final _responses = <FutureOr<http.Response> Function(http.Request)>[];
  final _byPath = <String, List<FutureOr<http.Response> Function(http.Request)>>{};
  final requests = <http.Request>[];

  /// Answers the next `[method] [path]` request, for example
  /// `answerAt('GET', '/v1/feedback/3', ...)`.
  void answerAt(String method, String path, Map<String, dynamic> json, {int status = 200}) =>
      _queue(method, path).add((_) => http.Response(jsonEncode(json), status));

  /// Answers the next `[method] [path]` request once [gate] completes.
  void answerAtLater(
    String method,
    String path,
    Future<void> gate,
    Map<String, dynamic> json, {
    int status = 200,
  }) => _queue(method, path).add((_) async {
    await gate;
    return http.Response(jsonEncode(json), status);
  });

  void failAt(String method, String path, {int status = 500, String code = 'server_error'}) =>
      _queue(method, path).add(
        (_) => http.Response(jsonEncode({'error': {'code': code, 'message': 'x'}}), status),
      );

  /// The next `[method] [path]` request finds no connection.
  void offlineAt(String method, String path) =>
      _queue(method, path).add((_) => throw const SocketException('Network is unreachable'));

  /// The next `[method] [path]` request answers [body] as it is.
  void answerRawAt(String method, String path, String body, {int status = 200}) =>
      _queue(method, path).add((_) => http.Response(body, status));

  List<FutureOr<http.Response> Function(http.Request)> _queue(String method, String path) =>
      _byPath.putIfAbsent('$method $path', () => []);

  void answer(Map<String, dynamic> json, {int status = 200}) =>
      _responses.add((_) => http.Response(jsonEncode(json), status));

  /// Answers once [gate] completes, to test what happens meanwhile.
  void answerLater(Future<void> gate, Map<String, dynamic> json, {int status = 200}) =>
      _responses.add((_) async {
        await gate;
        return http.Response(jsonEncode(json), status);
      });

  void fail({int status = 500, String code = 'server_error', Map<String, dynamic>? details}) => _responses.add(
    (_) => http.Response(
      jsonEncode({
        'error': {'code': code, 'message': 'x', if (details != null) 'details': details},
      }),
      status,
    ),
  );

  late final http.Client client = MockClient((request) async {
    requests.add(request);
    final queue = _byPath['${request.method} ${request.url.path}'];
    if (queue != null && queue.isNotEmpty) return queue.removeAt(0)(request);
    return _responses.removeAt(0)(request);
  });

  /// One API client, shared by the repositories built from this backend.
  late final ApiClient api = ApiClient(
    backendUrl: 'https://example.com',
    appId: 'inventory',
    httpClient: client,
  );

  FeedbackRepository repository({PrefsCache? cache}) => FeedbackRepository(api, cache ?? PrefsCache());

  CommentRepository commentRepository(FeedbackRepository feedback) => CommentRepository(api, feedback);
}
