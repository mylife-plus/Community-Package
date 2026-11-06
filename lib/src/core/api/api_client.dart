import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../errors/app_error.dart';

/// HTTP client for the community Worker. Every failure becomes an [AppError].
class ApiClient {
  ApiClient({
    required String backendUrl,
    required this.appId,
    Future<String?> Function()? anonId,
    http.Client? httpClient,
    this.timeout = defaultTimeout,
  }) : _baseUrl = _trimSlash(backendUrl),
       _anonId = anonId ?? _noAnonId,
       _http = httpClient ?? http.Client();

  /// Not tuned yet: a guess for a single D1 query over a mobile network.
  static const defaultTimeout = Duration(seconds: 15);

  final String _baseUrl;
  final http.Client _http;
  final String appId;
  final Duration timeout;

  /// The reader's app language, sent as `?lang=` so content can be
  /// translated. Updated by the package's root widget.
  String languageCode = 'en';

  /// The user's anonymous ID, asked for on every request. Null until the
  /// user agreed to the privacy notice, and then no `X-Anon-Id` is sent.
  final Future<String?> Function() _anonId;

  /// GET `/v1[path]` and decode the JSON object it returns.
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> query = const {},
  }) async {
    final uri = Uri.parse('$_baseUrl/v1$path').replace(
      queryParameters: {
        for (final entry in query.entries)
          if (entry.value != null) entry.key: entry.value!,
        'lang': languageCode,
      },
    );
    final headers = await _headers();
    final http.Response response;
    try {
      response = await _http.get(uri, headers: headers).timeout(timeout);
    } on SocketException catch (e) {
      // http's IOClient wraps socket failures in a ClientException that also
      // implements SocketException (package:http lib/src/io_client.dart), so
      // this must come before the ClientException clause.
      debugPrint('community api: offline: $e');
      throw const AppError(AppErrorType.offline);
    } on TimeoutException {
      throw const AppError(AppErrorType.network, message: 'Request timed out');
    } on http.ClientException catch (e) {
      throw AppError(AppErrorType.network, message: e.message);
    }
    return _decode(response);
  }

  Future<Map<String, String>> _headers() async {
    final anonId = await _anonId();
    return {
      'Accept': 'application/json',
      'X-App-Id': appId,
      if (anonId != null) 'X-Anon-Id': anonId,
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    Object? body;
    try {
      body = response.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      body = null;
    }
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (!ok) {
      final error = AppError.fromResponse(response.statusCode, body);
      debugPrint('community api: ${response.statusCode} $error');
      throw error;
    }
    if (body is! Map<String, dynamic>) {
      throw const AppError(AppErrorType.network, message: 'Unreadable response');
    }
    return body;
  }

  static Future<String?> _noAnonId() async => null;

  static String _trimSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
