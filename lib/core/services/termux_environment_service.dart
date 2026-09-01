import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TermuxEnvironmentStatus {
  uninstalled,
  downloading,
  extracting,
  configuring,
  ready,
  error,
}

class TermuxEnvironmentService {
  TermuxEnvironmentStatus _status = TermuxEnvironmentStatus.uninstalled;
  String _statusMessage = 'Not initialized';
  double _progress = 0.0;
  String? _detectedArch;
  String? _rootPath;

  final _stateController =
      StreamController<TermuxEnvironmentStatus>.broadcast();

  TermuxEnvironmentStatus get status => _status;
  String get statusMessage => _statusMessage;
  double get progress => _progress;
  String get detectedArchitecture => _detectedArch ?? 'aarch64';
  Stream<TermuxEnvironmentStatus> get statusStream => _stateController.stream;

  // FIX 1: Reliable check for installation that won't fail on symlink byte lengths
  bool get isBootstrapInstalled {
    try {
      final binDir = Directory(binPath);
      return binDir.existsSync() && binDir.listSync().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool get isReady =>
      _status == TermuxEnvironmentStatus.ready && isBootstrapInstalled;

  String get prefixPath => p.join(_rootPath ?? '', 'usr');
  String get binPath => p.join(prefixPath, 'bin');
  String get libPath => p.join(prefixPath, 'lib');
  String get homePath => p.join(_rootPath ?? '', 'home');
  String get tmpPath => p.join(prefixPath, 'tmp');
  String get bashBinaryPath => p.join(binPath, 'bash');
  String get shBinaryPath => p.join(binPath, 'sh');
  String get prootBinaryPath => p.join(binPath, 'proot');

  Future<void> initialize({String? customBasePath}) async {
    try {
      if (customBasePath != null) {
        _rootPath = customBasePath;
      } else {
        final docs = await getApplicationDocumentsDirectory();
        _rootPath = p.join(docs.path, 'termux');
      }

      _detectedArch = await detectArchitecture();

      bool wasInstalled = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        wasInstalled = prefs.getBool('pref_termux_installed') ?? false;
      } catch (_) {}

      final hasBinaries = isBootstrapInstalled;

      // FIX 2: Trust the filesystem. If files exist, restore the state.
      if (wasInstalled || hasBinaries) {
        _status = TermuxEnvironmentStatus.ready;
        _statusMessage = 'Termux environment ready ($_detectedArch)';
        _progress = 1.0;

        if (!wasInstalled) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('pref_termux_installed', true);
          } catch (_) {}
        }

        if (!Platform.isWindows) {
          await ensureBinariesExecutable(prefixPath);
        }
      } else {
        _status = TermuxEnvironmentStatus.uninstalled;
        _statusMessage = 'Termux bootstrap not installed';
        _progress = 0.0;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('pref_termux_installed', false);
        } catch (_) {}
      }
    } catch (e) {
      _status = TermuxEnvironmentStatus.error;
      _statusMessage = 'Failed to initialize: $e';
    }
    _stateController.add(_status);
  }

  Future<String> detectArchitecture() async {
    if (Platform.isAndroid) {
      try {
        final result = await Process.run('getprop', ['ro.product.cpu.abi']);
        final abi = result.stdout.toString().trim().toLowerCase();
        if (abi.contains('arm64') || abi.contains('aarch64')) return 'aarch64';
        if (abi.contains('armeabi') || abi.contains('armv7')) return 'arm';
        if (abi.contains('x86_64')) return 'x86_64';
        if (abi.contains('x86')) return 'i686';
      } catch (_) {}

      try {
        final result = await Process.run('uname', ['-m']);
        final machine = result.stdout.toString().trim().toLowerCase();
        if (machine.contains('aarch64') || machine.contains('arm64'))
          return 'aarch64';
        if (machine.contains('arm')) return 'arm';
        if (machine.contains('x86_64')) return 'x86_64';
      } catch (_) {}
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final arch = Platform.version.toLowerCase();
      if (arch.contains('arm64') || arch.contains('aarch64')) return 'aarch64';
      return 'x86_64';
    }

    return 'aarch64';
  }

  Future<bool> installEnvironment({
    void Function(String message, double progress)? onProgress,
  }) async {
    if (_rootPath == null) {
      await initialize();
    }

    try {
      _status = TermuxEnvironmentStatus.downloading;
      _statusMessage =
          'Downloading Termux bootstrap for $detectedArchitecture...';
      _progress = 0.05;
      _stateController.add(_status);
      onProgress?.call(_statusMessage, _progress);

      final arch = detectedArchitecture;
      final candidateUrls = await _getCandidateBootstrapUrls(arch);

      List<int>? zipBytes;
      String? lastError;

      for (int i = 0; i < candidateUrls.length; i++) {
        final url = candidateUrls[i];
        try {
          if (i > 0) {
            _statusMessage =
                'Retrying with mirror ${i + 1}/${candidateUrls.length}...';
            onProgress?.call(_statusMessage, _progress);
          }
          zipBytes = await _downloadFile(
            url,
            onProgress: (downloadProgress) {
              _progress = 0.05 + (downloadProgress * 0.45);
              _statusMessage =
                  'Downloading bootstrap ($arch) ${(downloadProgress * 100).toInt()}%';
              _stateController.add(_status);
              onProgress?.call(_statusMessage, _progress);
            },
          );
          if (zipBytes.isNotEmpty) {
            break;
          }
        } catch (err) {
          lastError = err.toString();
        }
      }

      if (zipBytes == null || zipBytes.isEmpty) {
        throw Exception(
          lastError ?? 'Failed to download bootstrap archive from all mirrors',
        );
      }

      _status = TermuxEnvironmentStatus.extracting;
      _statusMessage = 'Extracting bootstrap archive...';
      _progress = 0.55;
      _stateController.add(_status);
      onProgress?.call(_statusMessage, _progress);

      final archive = ZipDecoder().decodeBytes(zipBytes);
      final totalEntries = archive.length;
      int processedEntries = 0;

      final usrDir = Directory(prefixPath);
      if (!await usrDir.exists()) {
        await usrDir.create(recursive: true);
      }

      final homeDir = Directory(homePath);
      if (!await homeDir.exists()) {
        await homeDir.create(recursive: true);
      }

      final tmpDir = Directory(tmpPath);
      if (!await tmpDir.exists()) {
        await tmpDir.create(recursive: true);
      }

      String? symlinksContent;

      for (final file in archive) {
        final filename = file.name;
        if (filename == 'SYMLINKS.txt') {
          symlinksContent = utf8.decode(file.content as List<int>);
          continue;
        }

        final outPath = p.join(prefixPath, filename);
        if (file.isFile) {
          final outFile = File(outPath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(outPath).create(recursive: true);
        }

        processedEntries++;
        if (processedEntries % 100 == 0) {
          _progress = 0.55 + ((processedEntries / totalEntries) * 0.25);
          _stateController.add(_status);
          onProgress?.call(_statusMessage, _progress);
        }
      }

      _status = TermuxEnvironmentStatus.configuring;
      _statusMessage = 'Rebuilding symbolic links and permissions...';
      _progress = 0.82;
      _stateController.add(_status);
      onProgress?.call(_statusMessage, _progress);

      if (symlinksContent != null) {
        await processSymlinks(symlinksContent, prefixPath);
      }

      if (!Platform.isWindows) {
        await ensureBinariesExecutable(prefixPath);
      }

      // FIX 3: Patch hardcoded /data/data/com.termux paths in shell scripts
      await _patchTermuxScripts();

      await _configureAptSources();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pref_termux_installed', true);
      } catch (_) {}

      _status = TermuxEnvironmentStatus.ready;
      _statusMessage = 'Termux runtime ready ($arch)';
      _progress = 1.0;
      _stateController.add(_status);
      onProgress?.call(_statusMessage, _progress);
      return true;
    } catch (e) {
      _status = TermuxEnvironmentStatus.error;
      _statusMessage = 'Installation failed: $e';
      _stateController.add(_status);
      onProgress?.call(_statusMessage, _progress);
      return false;
    }
  }

  // Helper method to replace hardcoded termux paths in scripts to prevent "bad interpreter"
  Future<void> _patchTermuxScripts() async {
    if (Platform.isWindows) return;
    try {
      final binDir = Directory(binPath);
      if (!binDir.existsSync()) return;

      final termuxPrefix = '/data/data/com.termux/files/usr';

      for (final entity in binDir.listSync()) {
        if (entity is File) {
          try {
            // Only process likely scripts to avoid corrupting large compiled binaries
            if (entity.lengthSync() < 256 * 1024) {
              final bytes = entity.readAsBytesSync();
              // Check if file starts with a shebang '#!'
              if (bytes.length > 2 && bytes[0] == 35 && bytes[1] == 33) {
                final content = utf8.decode(bytes, allowMalformed: true);
                if (content.contains(termuxPrefix)) {
                  final newContent = content.replaceAll(
                    termuxPrefix,
                    prefixPath,
                  );
                  entity.writeAsStringSync(newContent);
                }
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  static const List<String> _knownBootstrapReleaseTags = [
    'bootstrap-2026.08.30-r1+apt.android-7',
    'bootstrap-2026.08.23-r1+apt.android-7',
    'bootstrap-2026.08.16-r1+apt.android-7',
    'bootstrap-2026.08.09-r1+apt.android-7',
    'bootstrap-2026.08.02-r1+apt.android-7',
  ];

  Future<List<String>> _getCandidateBootstrapUrls(String arch) async {
    final urls = <String>[];

    try {
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 6);
      final request = await httpClient.getUrl(
        Uri.parse(
          'https://api.github.com/repos/termux/termux-packages/releases',
        ),
      );
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Nivora-Mobile/1.0.0 (Linux; Android)',
      );
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github.v3+json',
      );
      final response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        final body = await response.transform(utf8.decoder).join();
        final list = json.decode(body) as List<dynamic>;
        for (final release in list) {
          final assets = release['assets'] as List<dynamic>? ?? [];
          for (final asset in assets) {
            if (asset['name'] == 'bootstrap-$arch.zip') {
              final dlUrl = asset['browser_download_url'] as String?;
              if (dlUrl != null && !urls.contains(dlUrl)) {
                urls.add(dlUrl);
              }
            }
          }
          if (urls.isNotEmpty) break;
        }
      }
      httpClient.close();
    } catch (_) {}

    for (final tag in _knownBootstrapReleaseTags) {
      final encodedTag = Uri.encodeComponent(tag);
      final url =
          'https://github.com/termux/termux-packages/releases/download/$encodedTag/bootstrap-$arch.zip';
      if (!urls.contains(url)) {
        urls.add(url);
      }
    }

    return urls;
  }

  Future<List<int>> _downloadFile(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 15);

    try {
      var currentUri = Uri.parse(url);
      HttpClientResponse? response;

      for (int redirect = 0; redirect < 8; redirect++) {
        final request = await httpClient.getUrl(currentUri);
        request.followRedirects = false;
        request.headers.set(
          HttpHeaders.userAgentHeader,
          'Nivora-Mobile/1.0.0 (Linux; Android)',
        );
        request.headers.set(HttpHeaders.acceptHeader, '*/*');

        response = await request.close();

        if (response.isRedirect ||
            response.statusCode == HttpStatus.movedPermanently ||
            response.statusCode == HttpStatus.movedTemporarily ||
            response.statusCode == HttpStatus.seeOther ||
            response.statusCode == HttpStatus.temporaryRedirect ||
            response.statusCode == HttpStatus.permanentRedirect) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location == null) {
            throw Exception('Redirect returned no Location header');
          }
          currentUri = currentUri.resolve(location);
          continue;
        }

        break;
      }

      if (response == null || response.statusCode != HttpStatus.ok) {
        throw Exception('HTTP error ${response?.statusCode ?? "unknown"}');
      }

      final contentLength = response.contentLength;
      final bytes = <int>[];
      int received = 0;

      await for (final chunk in response) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (contentLength > 0 && onProgress != null) {
          onProgress(received / contentLength);
        }
      }

      return bytes;
    } finally {
      httpClient.close();
    }
  }

  static Future<void> processSymlinks(
    String symlinksContent,
    String rootUsrPath,
  ) async {
    final lines = symlinksContent.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final parts = trimmed.split('←');
      if (parts.length != 2) continue;

      final target = parts[0].trim();
      final linkRelPath = parts[1].trim();
      final fullLinkPath = p.join(rootUsrPath, linkRelPath);

      try {
        final linkFile = File(fullLinkPath);
        if (await linkFile.exists()) {
          await linkFile.delete();
        }
        final linkDir = Directory(fullLinkPath);
        if (await linkDir.exists()) {
          await linkDir.delete(recursive: true);
        }

        final link = Link(fullLinkPath);
        await link.parent.create(recursive: true);
        await link.create(target);
      } catch (_) {
        try {
          final resolvedTarget = p.isAbsolute(target)
              ? p.join(
                  rootUsrPath,
                  target.replaceFirst(
                    RegExp(r'^/data/data/com\.termux/files/usr/'),
                    '',
                  ),
                )
              : p.normalize(p.join(p.dirname(fullLinkPath), target));

          final targetFile = File(resolvedTarget);
          if (await targetFile.exists()) {
            await targetFile.copy(fullLinkPath);
          }
        } catch (_) {}
      }
    }
  }

  Future<bool> ensureBinariesExecutable([String? rootUsrPath]) async {
    if (Platform.isWindows) return true;

    final usrPath = rootUsrPath ?? prefixPath;
    final binDir = Directory(p.join(usrPath, 'bin'));
    final libexecDir = Directory(p.join(usrPath, 'libexec'));

    _applyFfiChmodRecursive(binDir);
    _applyFfiChmodRecursive(libexecDir);

    if (Platform.isAndroid) {
      try {
        if (await binDir.exists()) {
          await Process.run('/system/bin/sh', [
            '-c',
            '/system/bin/chmod -R 755 "${binDir.path}" 2>/dev/null || /system/bin/toybox chmod -R 755 "${binDir.path}" 2>/dev/null || chmod -R 755 "${binDir.path}" 2>/dev/null',
          ]);
        }
        if (await libexecDir.exists()) {
          await Process.run('/system/bin/sh', [
            '-c',
            '/system/bin/chmod -R 755 "${libexecDir.path}" 2>/dev/null || /system/bin/toybox chmod -R 755 "${libexecDir.path}" 2>/dev/null || chmod -R 755 "${libexecDir.path}" 2>/dev/null',
          ]);
        }
      } catch (_) {}
    } else if (Platform.isLinux || Platform.isMacOS) {
      try {
        if (await binDir.exists()) {
          await Process.run('chmod', ['-R', '755', binDir.path]);
        }
        if (await libexecDir.exists()) {
          await Process.run('chmod', ['-R', '755', libexecDir.path]);
        }
      } catch (_) {}
    }

    return true;
  }

  void _applyFfiChmodRecursive(Directory dir) {
    try {
      if (!dir.existsSync()) return;
      _PosixChmod.chmod(dir.path, 493);
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        try {
          _PosixChmod.chmod(entity.path, 493);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _configureAptSources() async {
    try {
      final etcAptDir = Directory(p.join(prefixPath, 'etc', 'apt'));
      if (!await etcAptDir.exists()) {
        await etcAptDir.create(recursive: true);
      }
      final sourcesList = File(p.join(etcAptDir.path, 'sources.list'));
      await sourcesList.writeAsString(
        'deb https://packages.termux.dev/apt/termux-main stable main\n'
        'deb https://packages-cf.termux.dev/apt/termux-main stable main\n',
      );
    } catch (_) {}
  }

  Map<String, String> getEnvironmentVariables({String? workingDirectory}) {
    return {
      'PREFIX': prefixPath,
      'PATH': '$binPath:$binPath/applets:/system/bin:/system/xbin',
      'LD_LIBRARY_PATH': libPath,
      'HOME': homePath,
      'TMPDIR': tmpPath,
      'TERM': 'xterm-256color',
      'COLORTERM': 'truecolor',
      'LANG': 'en_US.UTF-8',
      'PWD': workingDirectory ?? homePath, // FIX 4: Corrected syntax error
    };
  }

  List<String> wrapCommandWithProot({
    required String command,
    required String workingDirectory,
  }) {
    final proot = File(prootBinaryPath);
    if (proot.existsSync()) {
      return [
        prootBinaryPath,
        '-0',
        '-b',
        '$prefixPath:/data/data/com.termux/files/usr',
        '-b',
        '$homePath:/data/data/com.termux/files/home',
        '-b',
        '/dev',
        '-b',
        '/proc',
        '-b',
        '/sys',
        if (workingDirectory.isNotEmpty) ...[
          '-b',
          '$workingDirectory:$workingDirectory',
        ],
        '-w',
        workingDirectory.isNotEmpty ? workingDirectory : homePath,
        '/data/data/com.termux/files/usr/bin/bash',
        '-c',
        command,
      ];
    }

    final bash = File(bashBinaryPath);
    final executable = bash.existsSync() ? bashBinaryPath : shBinaryPath;
    return [executable, '-c', command];
  }

  void dispose() {
    _stateController.close();
  }
}

typedef _NativeChmod =
    ffi.Int32 Function(ffi.Pointer<Utf8> path, ffi.Uint32 mode);
typedef _DartChmod = int Function(ffi.Pointer<Utf8> path, int mode);

class _PosixChmod {
  static final _DartChmod? _chmod = () {
    if (Platform.isWindows) return null;
    try {
      final lib = Platform.isAndroid || Platform.isLinux
          ? ffi.DynamicLibrary.open('libc.so')
          : Platform.isMacOS
          ? ffi.DynamicLibrary.open('/usr/lib/libSystem.B.dylib')
          : ffi.DynamicLibrary.process();
      return lib.lookupFunction<_NativeChmod, _DartChmod>('chmod');
    } catch (_) {
      return null;
    }
  }();

  static bool chmod(String path, int mode) {
    final fn = _chmod;
    if (fn == null) return false;
    try {
      final nativePath = path.toNativeUtf8();
      try {
        final res = fn(nativePath, mode);
        return res == 0;
      } finally {
        malloc.free(nativePath);
      }
    } catch (_) {
      return false;
    }
  }
}
