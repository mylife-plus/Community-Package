import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:community_package/src/core/api/api_client.dart';
import 'package:community_package/src/core/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _client(
  MockClientHandler handler, {
  Duration timeout = ApiClient.defaultTimeout,
  Future<String?> Function()? anonId,
}) => ApiClient(
  backendUrl: 'https://example.com/',
  appId: 'inventory',
  anonId: anonId,
  httpClient: MockClient(handler),
  timeout: timeout,
);

Matcher _appError(AppErrorType type) =>
    throwsA(isA<AppError>().having((e) => e.type, 'type', type));

void main() {
  test('sends the app ID, the language and the query', () async {
    late http.Request sent;
    final api = _client((request) async {
      sent = request;
      return http.Response('{"ok":true}', 200);
    })..languageCode = 'de';

    final body = await api.getJson('/feedback', query: {'cursor': 'abc', 'skip': null});

    expect(body, {'ok': true});
    expect(sent.url.toString(), 'https://example.com/v1/feedback?cursor=abc&lang=de');
    expect(sent.headers['X-App-Id'], 'inventory');
    expect(sent.headers.containsKey('X-Anon-Id'), isFalse);
  });

  test('sends the anonymous ID once there is one', () async {
    late http.Request sent;
    final api = _client(
      (request) async {
        sent = request;
        return http.Response('{}', 200);
      },
      anonId: () async => 'f2b7c1de-0000-4000-8000-000000000001',
    );

    await api.getJson('/feedback');

    expect(sent.headers['X-Anon-Id'], 'f2b7c1de-0000-4000-8000-000000000001');
  });

  test('turns the backend error shape into an AppError', () async {
    final api = _client(
      (_) async => http.Response(
        jsonEncode({
          'error': {
            'code': 'blocked',
            'message': 'Blocked',
            'details': {'reason': 'spam'},
          },
        }),
        403,
      ),
    );

    await expectLater(
      api.getJson('/feedback'),
      throwsA(
        isA<AppError>()
            .having((e) => e.type, 'type', AppErrorType.blocked)
            .having((e) => e.details, 'details', {'reason': 'spam'}),
      ),
    );
  });

  test('a 400 is a bad request', () async {
    final api = _client(
      (_) async => http.Response('{"error":{"code":"bad_request","message":"Unknown app"}}', 400),
    );

    await expectLater(api.getJson('/feedback'), _appError(AppErrorType.badRequest));
  });

  test('a non-JSON 502 is a server error', () async {
    final api = _client((_) async => http.Response('<html>Bad gateway</html>', 502));

    await expectLater(api.getJson('/feedback'), _appError(AppErrorType.server));
  });

  test('a socket failure means offline', () async {
    final api = _client((_) async => throw const SocketException('Failed host lookup'));

    await expectLater(api.getJson('/feedback'), _appError(AppErrorType.offline));
  });

  test('a timeout is a network error', () async {
    final api = _client(
      (_) => Completer<http.Response>().future,
      timeout: const Duration(milliseconds: 10),
    );

    await expectLater(api.getJson('/feedback'), _appError(AppErrorType.network));
  });

  test('a 200 that is not a JSON object is a network error', () async {
    final api = _client((_) async => http.Response('[]', 200));

    await expectLater(api.getJson('/feedback'), _appError(AppErrorType.network));
  });
}
