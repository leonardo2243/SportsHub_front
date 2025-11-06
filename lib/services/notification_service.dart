import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  final _controller = StreamController<String>.broadcast();
  http.Client? _client;
  StreamSubscription? _subscription;
  bool _isConnected = false;

  Stream<String> get notificationStream => _controller.stream;
  bool get isConnected => _isConnected;

  // Usa la IP de tu PC si pruebas en un dispositivo físico.
  // Usa 10.0.2.2 para el emulador de Android.
  // Usa localhost o 127.0.0.1 para web o escritorio.
  final String _baseUrl = 'http://10.0.2.2:8000';

  Future<void> connect(String userId) async {
    if (_isConnected) return;

    final url = Uri.parse('$_baseUrl/notifications/stream?user_id=$userId');

    try {
      _client = http.Client();
      final request = http.Request("GET", url);
      request.headers["Cache-Control"] = "no-cache";
      request.headers["Accept"] = "text/event-stream";

      final response = await _client!.send(request);

      if (response.statusCode == 200) {
        _isConnected = true;
        _controller.add(
          json.encode({"type": "status", "content": "Conexión establecida"}),
        );

        _subscription = response.stream
            .transform(utf8.decoder)
            .listen(
              (event) {
                if (event.startsWith('data: ')) {
                  final message = event.substring(6).trim();
                  if (message.isNotEmpty) _controller.add(message);
                }
              },
              onDone: () => disconnect(),
              onError: (e) {
                _controller.add(
                  json.encode({"type": "status", "content": "Error: ${e.toString()}"}),
                );
                disconnect();
              },
              cancelOnError: true,
            );
      } else {
        _controller.add(
          json.encode({
            "type": "status",
            "content": "Error del servidor: ${response.statusCode}",
          }),
        );
        disconnect();
      }
    } catch (e) {
      _controller.add(
        json.encode({"type": "status", "content": "Excepción al conectar: $e"}),
      );
      disconnect();
    }
  }

  void disconnect() {
    if (!_isConnected) return;

    _controller.add(json.encode({"type": "status", "content": "Conexión cerrada."}));
    _subscription?.cancel();
    _client?.close();
    _client = null;
    _subscription = null;
    _isConnected = false;
  }

  void dispose() {
    _controller.close();
    disconnect();
  }
}
