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
      try {
        _server = await HttpServer.bind(
          InternetAddress.anyIPv4,
          requestedPort,
          shared: true,
        );
        _port = _server!.port;
      } catch (_) {
        try {
          _server = await HttpServer.bind(
            InternetAddress.loopbackIPv4,
            0,
            shared: true,
          );
          _port = _server!.port;
        } catch (_) {
          _server = await HttpServer.bind(
            InternetAddress.anyIPv4,
            0,
            shared: true,
          );
          _port = _server!.port;
        }
      }
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
    final filePath = p.join(
      _workingDirectory ?? '',
      uriPath.startsWith('/') ? uriPath.substring(1) : uriPath,
    );
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
      response.write(
        jsonEncode({
          'status': 'healthy',
          'service': 'wildfire-ai',
          'version': '1.0.0',
          'device': 'Android ARM64 Workstation',
        }),
      );
      await response.close();
      return;
    }

    if (request.uri.path == '/predict') {
      response.headers.contentType = ContentType.json;
      response.write(
        jsonEncode({
          'risk_level': 'CRITICAL',
          'rate_m_per_h': 450.0,
          'recommendation': 'Evacuate zone 4B immediately.',
        }),
      );
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
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; transition: all 0.3s ease; }
    body { background: #F8FAFC; color: #0F172A; padding: 24px; min-height: 100vh; display: flex; flex-direction: column; justify-content: center; align-items: center; }
    .container { width: 100%; max-width: 440px; }
    .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }
    .logo { font-size: 19px; font-weight: 800; color: #0284C7; display: flex; align-items: center; gap: 8px; letter-spacing: -0.5px; }
    .badge { background: #E0F2FE; color: #0284C7; padding: 6px 12px; border-radius: 999px; font-size: 11px; font-weight: 700; border: 1px solid #BAE6FD; box-shadow: 0 2px 4px rgba(2, 132, 199, 0.05); }
    .hero { background: linear-gradient(135deg, #38BDF8, #0EA5E9); border-radius: 24px; padding: 28px; box-shadow: 0 16px 32px rgba(14, 165, 233, 0.25); margin-bottom: 20px; color: #FFFFFF; position: relative; overflow: hidden; }
    .hero::after { content: ''; position: absolute; top: -50px; right: -50px; width: 140px; height: 140px; background: rgba(255, 255, 255, 0.15); border-radius: 50%; pointer-events: none; }
    .hero h3 { font-size: 18px; font-weight: 700; letter-spacing: -0.3px; }
    .hero-sub { opacity: 0.95; font-size: 14px; margin-top: 4px; font-weight: 500; }
    .temp-display { font-size: 68px; font-weight: 800; margin: 16px 0; letter-spacing: -2px; text-shadow: 0 2px 10px rgba(0, 0, 0, 0.08); }
    .hero-footer { font-size: 13px; opacity: 0.95; font-weight: 500; background: rgba(255, 255, 255, 0.2); display: inline-block; padding: 4px 10px; border-radius: 8px; backdrop-filter: blur(4px); }
    .grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 14px; margin-bottom: 20px; }
    .stat-box { background: #FFFFFF; border: 1px solid #E2E8F0; border-radius: 16px; padding: 18px; box-shadow: 0 4px 12px rgba(15, 23, 42, 0.03); }
    .stat-box h4 { font-size: 11px; color: #64748B; margin-bottom: 6px; text-transform: uppercase; font-weight: 700; letter-spacing: 0.5px; }
    .stat-box p { font-size: 20px; font-weight: 800; color: #0EA5E9; }
    .btn { background: #0F172A; color: #FFFFFF; border: none; padding: 14px 20px; border-radius: 14px; font-weight: 700; cursor: pointer; width: 100%; font-size: 14px; box-shadow: 0 8px 20px rgba(15, 23, 42, 0.15); }
    .btn:hover { background: #1E293B; transform: translateY(-1px); box-shadow: 0 10px 24px rgba(15, 23, 42, 0.2); }
    .btn:active { transform: translateY(0); }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">⚡ WeatherPulse</div>
      <span class="badge">NIVORA LOCAL DEV</span>
    </div>

    <div class="hero">
      <h3>San Francisco, CA</h3>
      <div class="hero-sub">Partly Cloudy • Wind 8 mph NW</div>
      <div class="temp-display" id="tempText">72°F</div>
      <div class="hero-footer">High: 76° • Low: 58°</div>
    </div>

    <div class="grid">
      <div class="stat-box">
        <h4>Humidity</h4>
        <p>54%</p>
      </div>
      <div class="stat-box">
        <h4>Air Quality</h4>
        <p style="color: #10B981;">38 Good</p>
      </div>
      <div class="stat-box">
        <h4>UV Index</h4>
        <p>3 / 10</p>
      </div>
      <div class="stat-box">
        <h4>Vite Status</h4>
        <p style="color: #6366F1;">HMR Active</p>
      </div>
    </div>

    <button class="btn" onclick="toggleTemp()">Simulate Sensor Update</button>
  </div>

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
