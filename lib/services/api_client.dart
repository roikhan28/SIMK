import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'simk_http_client_stub.dart'
    if (dart.library.io) 'simk_http_client_io.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client})
      : _client = client ?? createSimkHttpClient();

  final http.Client _client;
  String? _token;
  void Function()? onUnauthorized;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) async {
    final response = await _client
        .get(_uri(path, query), headers: _headers)
        .timeout(ApiConfig.timeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final response = await _client
        .post(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
        .timeout(ApiConfig.timeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    final response = await _client
        .put(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
        .timeout(ApiConfig.timeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await _client
        .delete(_uri(path), headers: _headers)
        .timeout(ApiConfig.timeout);
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } catch (_) {
        final preview = response.body.length > 120
            ? '${response.body.substring(0, 120)}...'
            : response.body;
        throw ApiException(
          'Respons server tidak valid (${response.statusCode}): $preview',
          statusCode: response.statusCode,
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (response.statusCode == 401 && onUnauthorized != null) {
      onUnauthorized!();
    }

    final message = _friendlyMessage(
      body['message'] as String? ??
          body['error'] as String? ??
          _statusHint(response.statusCode),
      response.statusCode,
    );
    throw ApiException(message, statusCode: response.statusCode);
  }

  String _friendlyMessage(String message, int code) {
    if (message == 'Method Not Allowed' || code == 405) {
      return 'API belum terhubung ke SIMK (masih ke CasaOS). '
          'Pastikan tunnel Cloudflare mengarah ke port 8081.';
    }
    return message;
  }

  String _statusHint(int code) {
    switch (code) {
      case 404:
        return 'Endpoint tidak ditemukan (404). Pastikan API SIMK sudah di-deploy di server.';
      case 405:
        return 'Metode tidak didukung (405). URL API mungkin mengarah ke layanan lain, bukan SIMK API.';
      case 502:
      case 503:
        return 'Server API tidak tersedia ($code).';
      default:
        return 'Terjadi kesalahan ($code)';
    }
  }
}
