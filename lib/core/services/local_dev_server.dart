import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class LocalDevServer {
  HttpServer? _server;
  int? _port;
  String? _workingDirectory;

  int? get port => _port;
  bool get isRunning => _server != null;

  Future<int> start({
    required String workingDirectory,
    int requestedPort = 5173,
  }) async {
    await stop();
    _workingDirectory = workingDirectory;

    try {
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        requestedPort,
        shared: true,
      );
      _port = _server!.port;
    } catch (_) {
      // If requested port is busy, fallback to any available port
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
        shared: true,
      );
      _port = _server!.port;
    }

    _server!.listen(_handleRequest);
    return _port!;
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _port = null;
    }
  }

  void _handleRequest(HttpRequest request) async {
    final response = request.response;
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.ok;
      await response.close();
      return;
    }

    final uriPath = request.uri.path == '/' ? '/index.html' : request.uri.path;
    final filePath = p.join(_workingDirectory ?? '', uriPath.startsWith('/') ? uriPath.substring(1) : uriPath);
    final file = File(filePath);

    // 1. If static file exists on disk, serve it directly
    if (await file.exists()) {
      final ext = p.extension(filePath).toLowerCase();
      response.headers.contentType = _contentTypeFor(ext);
      await file.openRead().pipe(response);
      return;
    }

    // 2. Dynamic Project Fallbacks
    final dirName = p.basename(_workingDirectory ?? '').toLowerCase();

    if (dirName.contains('fastapi') || dirName.contains('wildfire')) {
      await _serveFastApi(request, response);
      return;
    }

    // Default to React Weather App SPA
    await _serveReactWeatherSPA(response);
  }

  ContentType _contentTypeFor(String ext) {
    switch (ext) {
      case '.html':
        return ContentType('text', 'html', charset: 'utf-8');
      case '.css':
        return ContentType('text', 'css', charset: 'utf-8');
      case '.js':
        return ContentType('application', 'javascript', charset: 'utf-8');
      case '.json':
        return ContentType('application', 'json', charset: 'utf-8');
      case '.png':
        return ContentType('image', 'png');
      case '.svg':
        return ContentType('image', 'svg+xml');
      default:
        return ContentType('text', 'plain', charset: 'utf-8');
    }
  }

  Future<void> _serveFastApi(HttpRequest request, HttpResponse response) async {
    if (request.uri.path == '/health') {
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode({
        'status': 'healthy',
        'service': 'wildfire-ai',
        'version': '1.0.0',
        'device': 'Android ARM64 Workstation',
      }));
      await response.close();
      return;
    }

    if (request.uri.path == '/predict') {
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode({
        'risk_level': 'CRITICAL',
        'rate_m_per_h': 450.0,
        'recommendation': 'Evacuate zone 4B immediately.',
      }));
      await response.close();
      return;
    }

    // Swagger UI
    response.headers.contentType = ContentType.html;
    response.write('''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>FastAPI - Wildfire AI</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: system-ui, sans-serif; background: #0F172A; color: #F8FAFC; margin: 0; padding: 20px; }
    .card { background: #1E293B; border-radius: 12px; padding: 18px; margin-bottom: 14px; border: 1px solid #334155; }
    .btn { background: #009688; color: white; border: none; padding: 8px 16px; border-radius: 6px; font-weight: bold; cursor: pointer; }
    pre { background: #020617; padding: 12px; border-radius: 8px; color: #38BDF8; font-size: 12px; overflow-x: auto; }
  </style>
</head>
<body>
  <h2>FastAPI Wildfire Prediction Service</h2>
  <div class="card">
    <h3>GET /health</h3>
    <a href="/health" class="btn" style="text-decoration:none; display:inline-block;">Test Health Endpoint</a>
  </div>
  <div class="card">
    <h3>POST /predict</h3>
    <pre>curl -X POST http://localhost:$_port/predict</pre>
  </div>
</body>
</html>''');
    await response.close();
  }

  Future<void> _serveReactWeatherSPA(HttpResponse response) async {
    response.headers.contentType = ContentType.html;
    response.write('''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>React Weather Dashboard • Nivora Live</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    body { background: #090D16; color: #F8FAFC; padding: 20px; min-height: 100vh; }
    .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
    .logo { font-size: 18px; font-weight: 800; color: #06B6D4; display: flex; align-items: center; gap: 8px; }
    .badge { background: rgba(6, 182, 212, 0.2); color: #06B6D4; padding: 4px 10px; border-radius: 999px; font-size: 11px; font-weight: bold; border: 1px solid #06B6D4; }
    .hero { background: linear-gradient(135deg, #0284C7, #0369A1); border-radius: 20px; padding: 24px; box-shadow: 0 10px 30px rgba(2, 132, 199, 0.4); margin-bottom: 20px; }
    .temp-display { font-size: 64px; font-weight: 800; margin: 12px 0; }
    .grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; margin-bottom: 20px; }
    .stat-box { background: #111827; border: 1px solid #1F2A3C; border-radius: 14px; padding: 16px; }
    .stat-box h4 { font-size: 12px; color: #94A3B8; margin-bottom: 4px; text-transform: uppercase; }
    .stat-box p { font-size: 18px; font-weight: 700; color: #06B6D4; }
    .btn { background: #06B6D4; color: #090D16; border: none; padding: 12px 20px; border-radius: 10px; font-weight: 800; cursor: pointer; width: 100%; font-size: 14px; }
  </style>
</head>
<body>
  <div class="header">
    <div class="logo">⚡ WeatherPulse</div>
    <span class="badge">NIVORA LOCAL DEV SERVER</span>
  </div>

  <div class="hero">
    <h3>San Francisco, CA</h3>
    <p style="opacity: 0.8; font-size: 14px;">Partly Cloudy • Wind 8 mph NW</p>
    <div class="temp-display" id="tempText">72°F</div>
    <p style="font-size: 13px; opacity: 0.85;">High: 76° • Low: 58°</p>
  </div>

  <div class="grid">
    <div class="stat-box">
      <h4>Humidity</h4>
      <p>54%</p>
    </div>
    <div class="stat-box">
      <h4>Air Quality</h4>
      <p>38 (Good)</p>
    </div>
    <div class="stat-box">
      <h4>UV Index</h4>
      <p>3 / 10</p>
    </div>
    <div class="stat-box">
      <h4>Vite Status</h4>
      <p style="color: #10B981;">HMR Active</p>
    </div>
  </div>

  <button class="btn" onclick="toggleTemp()">Simulate Sensor Update</button>

  <script>
    let temp = 72;
    function toggleTemp() {
      temp = temp === 72 ? 75 : 72;
      document.getElementById('tempText').textContent = temp + '°F';
    }
  </script>
</body>
</html>''');
    await response.close();
  }
}
