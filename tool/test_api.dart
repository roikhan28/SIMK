import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:simk/services/simk_http_client_io.dart';

Future<void> main() async {
  final client = createSimkHttpClient();
  final response = await client.post(
    Uri.parse('https://api.rzaproject.my.id/auth/login'),
    headers: const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({'email': 'admin@simk.id', 'password': 'admin123'}),
  );
  print('Status: ${response.statusCode}');
  print('Body: ${response.body.substring(0, response.body.length.clamp(0, 100))}');
  client.close();
}
