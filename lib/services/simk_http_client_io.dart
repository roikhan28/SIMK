import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// HTTPS client that connects via IPv6 when available.
/// Workaround for duplicate Cloudflare tunnels (IPv4 → CasaOS, IPv6 → SIMK API).
class SimkHttpClient extends http.BaseClient {
  SimkHttpClient() : _fallback = http.Client();

  final http.Client _fallback;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.scheme != 'https') {
      return _fallback.send(request);
    }

    try {
      final v6 = await InternetAddress.lookup(
        request.url.host,
        type: InternetAddressType.IPv6,
      );
      if (v6.isEmpty) {
        return _fallback.send(request);
      }
      return await _sendOverIpv6(request, v6.first);
    } catch (_) {
      return _fallback.send(request);
    }
  }

  Future<http.StreamedResponse> _sendOverIpv6(
    http.BaseRequest request,
    InternetAddress address,
  ) async {
    final host = request.url.host;
    final bodyBytes = await request.finalize().toBytes();
    final path = request.url.hasQuery
        ? '${request.url.path}?${request.url.query}'
        : request.url.path;

    final headerLines = <String>[
      '${request.method} $path HTTP/1.1',
      'Host: $host',
      'Accept: application/json',
      'Connection: close',
    ];
    for (final entry in request.headers.entries) {
      if (entry.key.toLowerCase() == 'host') continue;
      headerLines.add('${entry.key}: ${entry.value}');
    }
    if (bodyBytes.isNotEmpty &&
        !request.headers.keys.any((k) => k.toLowerCase() == 'content-length')) {
      headerLines.add('Content-Length: ${bodyBytes.length}');
    }

    final tcp = await Socket.connect(address, request.url.port);
    final socket = await SecureSocket.secure(tcp, host: host);

    socket.write('${headerLines.join('\r\n')}\r\n\r\n');
    if (bodyBytes.isNotEmpty) {
      socket.add(bodyBytes);
    }

    final raw = await socket.cast<List<int>>().transform(utf8.decoder).join();
    await socket.close();

    final parsed = _parseRawResponse(raw, request.url);
    return http.StreamedResponse(
      Stream.value(utf8.encode(parsed.body)),
      parsed.statusCode,
      request: request,
      headers: parsed.headers,
      reasonPhrase: parsed.reasonPhrase,
    );
  }

  _RawHttpResponse _parseRawResponse(String raw, Uri url) {
    final sep = raw.indexOf('\r\n\r\n');
    if (sep == -1) {
      throw Exception('Invalid HTTP response');
    }

    final headerBlock = raw.substring(0, sep);
    final bodyPart = raw.substring(sep + 4);
    final headerLines = headerBlock.split('\r\n');
    final statusParts = headerLines.first.split(' ');
    final statusCode = int.parse(statusParts[1]);
    final reasonPhrase =
        statusParts.length > 2 ? statusParts.sublist(2).join(' ') : '';

    final headers = <String, String>{};
    for (final line in headerLines.skip(1)) {
      final colon = line.indexOf(':');
      if (colon == -1) continue;
      final name = line.substring(0, colon).trim();
      final value = line.substring(colon + 1).trim();
      headers[name.toLowerCase()] = headers.containsKey(name.toLowerCase())
          ? '${headers[name.toLowerCase()]}, $value'
          : value;
    }

    final body = headers['transfer-encoding'] == 'chunked'
        ? _decodeChunked(bodyPart)
        : bodyPart;

    return _RawHttpResponse(
      statusCode: statusCode,
      reasonPhrase: reasonPhrase,
      headers: headers,
      body: body,
    );
  }

  String _decodeChunked(String data) {
    final buffer = StringBuffer();
    var rest = data;
    while (rest.isNotEmpty) {
      final lineEnd = rest.indexOf('\r\n');
      if (lineEnd == -1) break;
      final size = int.tryParse(rest.substring(0, lineEnd), radix: 16) ?? 0;
      if (size == 0) break;
      final start = lineEnd + 2;
      buffer.write(rest.substring(start, start + size));
      rest = rest.substring(start + size + 2);
    }
    return buffer.toString();
  }

  @override
  void close() => _fallback.close();
}

class _RawHttpResponse {
  const _RawHttpResponse({
    required this.statusCode,
    required this.reasonPhrase,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final String reasonPhrase;
  final Map<String, String> headers;
  final String body;
}

http.Client createSimkHttpClient() => SimkHttpClient();
