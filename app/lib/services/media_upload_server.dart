import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'level_pack_store.dart';

/// Tiny LAN server so a phone/laptop can upload media into the TV app.
class MediaUploadServer {
  MediaUploadServer(this.store);

  final LevelPackStore store;
  HttpServer? _server;
  final _uploaded = StreamController<String>.broadcast();

  Stream<String> get uploaded => _uploaded.stream;
  bool get isRunning => _server != null;
  int get port => _server?.port ?? 8787;

  Future<String?> lanIp() async {
    try {
      for (final iface in await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      )) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> start({int port = 8787}) async {
    if (_server != null) return;
    final router = Router()
      ..get('/', _htmlPage)
      ..post('/upload', _upload);

    _server = await shelf_io.serve(
      const Pipeline().addMiddleware(logRequests()).addHandler(router.call),
      InternetAddress.anyIPv4,
      port,
    );
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> dispose() async {
    await stop();
    await _uploaded.close();
  }

  Response _htmlPage(Request request) {
    const html = '''
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Соня ДР — загрузка медиа</title>
<style>
  body { font-family: system-ui, sans-serif; background:#12161F; color:#F8F4EC;
         max-width:520px; margin:40px auto; padding:0 16px; }
  h1 { font-size:1.3rem; color:#FFD166; }
  .box { background:#1C2433; border:2px solid #8D99AE; border-radius:8px;
         padding:20px; margin-top:16px; }
  input, button { font-size:1rem; margin-top:12px; width:100%; padding:12px; }
  button { background:#E63946; color:white; border:0; border-radius:6px; }
  #status { margin-top:16px; color:#4CC9F0; white-space:pre-wrap; }
</style>
</head>
<body>
  <h1>Загрузка медиа на ТВ</h1>
  <p>Картинки, видео или аудио попадут в медиатеку игры. Потом на ТВ привяжите файл к уровню.</p>
  <div class="box">
    <form id="f">
      <input type="file" id="file" accept="image/*,video/*,audio/*" required />
      <button type="submit">Загрузить</button>
    </form>
    <div id="status"></div>
  </div>
<script>
const f = document.getElementById('f');
const status = document.getElementById('status');
f.addEventListener('submit', async (e) => {
  e.preventDefault();
  const file = document.getElementById('file').files[0];
  if (!file) return;
  status.textContent = 'Загрузка…';
  const res = await fetch('/upload?name=' + encodeURIComponent(file.name), {
    method: 'POST',
    headers: { 'Content-Type': 'application/octet-stream' },
    body: file
  });
  const text = await res.text();
  status.textContent = res.ok ? ('Готово: ' + text) : ('Ошибка: ' + text);
});
</script>
</body>
</html>
''';
    return Response.ok(html, headers: {'content-type': 'text/html; charset=utf-8'});
  }

  Future<Response> _upload(Request request) async {
    final name = request.url.queryParameters['name'] ??
        'upload_${DateTime.now().millisecondsSinceEpoch}';
    final bytes = await request.read().fold<List<int>>(
      <int>[],
      (prev, chunk) => prev..addAll(chunk),
    );
    if (bytes.isEmpty) {
      return Response(400, body: 'пустой файл');
    }
    final ref = await store.importBytes(name, bytes);
    _uploaded.add(ref);
    return Response.ok(
      jsonEncode({'ref': ref, 'name': name}),
      headers: {'content-type': 'application/json'},
    );
  }
}
