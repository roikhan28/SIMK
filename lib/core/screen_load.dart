import '../services/api_client.dart';

/// Runs an async load action and returns an error message, or null on success.
Future<String?> runScreenLoad(Future<void> Function() action) async {
  try {
    await action();
    return null;
  } on ApiException catch (e) {
    return e.message;
  } catch (e) {
    final msg = e.toString();
    if (msg.contains('TimeoutException')) {
      return 'Server tidak merespons. Periksa URL API dan koneksi internet.';
    }
    return msg.replaceFirst('ApiException: ', '');
  }
}
