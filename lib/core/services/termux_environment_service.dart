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

  static const Map<String, String> knownMirrors = {
    'official': 'https://packages.termux.dev/apt/termux-main',
    'grimler': 'https://grimler.se/termux/termux-main',
    'tuna': 'https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main',
    'bfsu': 'https://mirrors.bfsu.edu.cn/termux/apt/termux-main',
    'leaseweb': 'https://mirror.leaseweb.com/termux/apt/termux-main',
  };

  String _activeMirror = 'https://packages.termux.dev/apt/termux-main';
  String get activeMirror => _activeMirror;

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
        final savedMirror = prefs.getString('pref_termux_mirror');
        if (savedMirror != null && savedMirror.isNotEmpty) {
          _activeMirror = savedMirror;
        }
      } catch (_) {}

      final hasBinaries = isBootstrapInstalled;

      // FIX 2: Trust the filesystem. If files exist, restore and repair the state.
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

        // Auto-heal configuration, DPKG database, locks, and DNS
        await repairEnvironment();
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
        if (machine.contains('aarch64') || machine.contains('arm64')) {
          return 'aarch64';
        }
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

      // Comprehensive repair and configuration
      await repairEnvironment();

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

  /// Automatically repairs missing DPKG databases, stale locks, APT configs, DNS, and script paths.
  Future<bool> repairEnvironment() async {
    if (_rootPath == null) return false;
    try {
      // 1. Create all essential directories for DPKG and APT
      final dirsToCreate = [
        prefixPath,
        binPath,
        libPath,
        homePath,
        tmpPath,
        p.join(prefixPath, 'etc'),
        p.join(prefixPath, 'etc', 'apt'),
        p.join(prefixPath, 'etc', 'apt', 'apt.conf.d'),
        p.join(prefixPath, 'etc', 'apt', 'sources.list.d'),
        p.join(prefixPath, 'etc', 'dpkg'),
        p.join(prefixPath, 'etc', 'tls'),
        p.join(prefixPath, 'var'),
        p.join(prefixPath, 'var', 'lib'),
        p.join(prefixPath, 'var', 'lib', 'dpkg'),
        p.join(prefixPath, 'var', 'lib', 'dpkg', 'updates'),
        p.join(prefixPath, 'var', 'lib', 'dpkg', 'info'),
        p.join(prefixPath, 'var', 'lib', 'dpkg', 'alternatives'),
        p.join(prefixPath, 'var', 'lib', 'dpkg', 'triggers'),
        p.join(prefixPath, 'var', 'lib', 'dpkg', 'parts'),
        p.join(prefixPath, 'var', 'lib', 'apt'),
        p.join(prefixPath, 'var', 'lib', 'apt', 'lists'),
        p.join(prefixPath, 'var', 'lib', 'apt', 'lists', 'partial'),
        p.join(prefixPath, 'var', 'cache'),
        p.join(prefixPath, 'var', 'cache', 'apt'),
        p.join(prefixPath, 'var', 'cache', 'apt', 'archives'),
        p.join(prefixPath, 'var', 'cache', 'apt', 'archives', 'partial'),
        p.join(prefixPath, 'var', 'log'),
        p.join(prefixPath, 'var', 'log', 'apt'),
      ];

      for (final dirPath in dirsToCreate) {
        final d = Directory(dirPath);
        if (!await d.exists()) {
          await d.create(recursive: true);
        }
      }

      // 2. Ensure critical status and available files exist
      final dpkgStatus = File(p.join(prefixPath, 'var', 'lib', 'dpkg', 'status'));
      if (!await dpkgStatus.exists()) {
        await dpkgStatus.writeAsString('');
      }

      final dpkgAvailable = File(p.join(prefixPath, 'var', 'lib', 'dpkg', 'available'));
      if (!await dpkgAvailable.exists()) {
        await dpkgAvailable.writeAsString('');
      }

      // 3. Clear stale lock files that cause "database inaccessible" or "unable to lock"
      final lockFiles = [
        p.join(prefixPath, 'var', 'lib', 'dpkg', 'lock'),
        p.join(prefixPath, 'var', 'lib', 'dpkg', 'lock-frontend'),
        p.join(prefixPath, 'var', 'lib', 'apt', 'lists', 'lock'),
        p.join(prefixPath, 'var', 'cache', 'apt', 'archives', 'lock'),
      ];
      for (final lf in lockFiles) {
        final f = File(lf);
        if (await f.exists()) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }

      // 4. Configure APT paths (apt.conf and 00nivora)
      final aptConfContent = '''
Dir "$prefixPath";
Dir::State "$prefixPath/var/lib/apt";
Dir::State::status "$prefixPath/var/lib/dpkg/status";
Dir::Cache "$prefixPath/var/cache/apt";
Dir::Etc "$prefixPath/etc/apt";
Dir::Bin::methods "$prefixPath/lib/apt/methods";
Dir::Bin::dpkg "$prefixPath/bin/dpkg";
Dir::Log "$prefixPath/var/log/apt";
Acquire::Languages "none";
Acquire::Retries "3";
Acquire::http::Timeout "20";
Acquire::https::Timeout "20";
DPkg::Options {
  "--admindir=$prefixPath/var/lib/dpkg";
  "--instdir=$prefixPath";
};
''';
      await File(p.join(prefixPath, 'etc', 'apt', 'apt.conf'))
          .writeAsString(aptConfContent);
      await File(p.join(prefixPath, 'etc', 'apt', 'apt.conf.d', '00nivora'))
          .writeAsString(aptConfContent);

      // 5. Configure DPKG (dpkg.cfg)
      final dpkgCfgContent = '''
admindir $prefixPath/var/lib/dpkg
instdir $prefixPath
''';
      await File(p.join(prefixPath, 'etc', 'dpkg', 'dpkg.cfg'))
          .writeAsString(dpkgCfgContent);

      // 6. Configure DNS & Network resolution (resolv.conf and hosts)
      final resolvConf = File(p.join(prefixPath, 'etc', 'resolv.conf'));
      await resolvConf.writeAsString(
        'nameserver 8.8.8.8\n'
        'nameserver 1.1.1.1\n'
        'nameserver 8.8.4.4\n',
      );

      final hostsFile = File(p.join(prefixPath, 'etc', 'hosts'));
      if (!await hostsFile.exists()) {
        await hostsFile.writeAsString(
          '127.0.0.1 localhost\n'
          '::1 localhost\n',
        );
      }

      // 7. Ensure valid sources.list without invalid or dead mirrors
      final sourcesList = File(p.join(prefixPath, 'etc', 'apt', 'sources.list'));
      bool needSourcesWrite = !await sourcesList.exists();
      if (!needSourcesWrite) {
        final existingContent = await sourcesList.readAsString();
        if (existingContent.contains('packages-cf.termux.dev') ||
            existingContent.trim().isEmpty) {
          needSourcesWrite = true;
        }
      }
      if (needSourcesWrite) {
        await sourcesList.writeAsString(
          'deb $_activeMirror stable main\n',
        );
      }

      // 8. Create non-interactive wrapper for termux-change-repo
      await _installNonInteractiveChangeRepo();

      // 9. Patch shell scripts & permissions
      if (!Platform.isWindows) {
        await _patchTermuxScripts();
        await ensureBinariesExecutable(prefixPath);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Switches active APT repository mirror cleanly without requiring an interactive TUI.
  Future<bool> switchMirror(String mirrorKeyOrUrl) async {
    final key = mirrorKeyOrUrl.trim().toLowerCase();
    String targetUrl;
    if (knownMirrors.containsKey(key)) {
      targetUrl = knownMirrors[key]!;
    } else if (mirrorKeyOrUrl.startsWith('http://') ||
        mirrorKeyOrUrl.startsWith('https://')) {
      targetUrl = mirrorKeyOrUrl.trim();
    } else {
      return false;
    }

    _activeMirror = targetUrl;
    try {
      final etcAptDir = Directory(p.join(prefixPath, 'etc', 'apt'));
      if (!await etcAptDir.exists()) {
        await etcAptDir.create(recursive: true);
      }
      final sourcesList = File(p.join(etcAptDir.path, 'sources.list'));
      await sourcesList.writeAsString('deb $targetUrl stable main\n');

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pref_termux_mirror', targetUrl);
      } catch (_) {}

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _installNonInteractiveChangeRepo() async {
    try {
      final scriptFile = File(p.join(binPath, 'termux-change-repo'));
      final content = '''#!/bin/sh
# Nivora Non-Interactive Termux Mirror Switcher
MIRROR="\$1"
SOURCES="$prefixPath/etc/apt/sources.list"

case "\$MIRROR" in
  grimler)
    URL="https://grimler.se/termux/termux-main"
    ;;
  tuna)
    URL="https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main"
    ;;
  bfsu)
    URL="https://mirrors.bfsu.edu.cn/termux/apt/termux-main"
    ;;
  leaseweb)
    URL="https://mirror.leaseweb.com/termux/apt/termux-main"
    ;;
  official|main|*)
    URL="https://packages.termux.dev/apt/termux-main"
    ;;
esac

echo "deb \$URL stable main" > "\$SOURCES"
echo "Active mirror set to: \$URL"
echo "Updating package lists..."
"$binPath/apt" update
''';
      await scriptFile.writeAsString(content);
      if (!Platform.isWindows) {
        _PosixChmod.chmod(scriptFile.path, 493);
      }
    } catch (_) {}
  }

  // Helper method to replace hardcoded termux paths in scripts to prevent "bad interpreter"
  Future<void> _patchTermuxScripts() async {
    if (Platform.isWindows) return;
    try {
      final dirsToScan = [
        Directory(binPath),
        Directory(p.join(prefixPath, 'etc')),
      ];

      final termuxUsrPrefix = '/data/data/com.termux/files/usr';
      final termuxHomePrefix = '/data/data/com.termux/files/home';

      for (final dir in dirsToScan) {
        if (!dir.existsSync()) continue;
        for (final entity in dir.listSync(recursive: true, followLinks: false)) {
          if (entity is File) {
            try {
              if (entity.lengthSync() < 256 * 1024) {
                final bytes = entity.readAsBytesSync();
                if (bytes.length > 2 && bytes[0] == 35 && bytes[1] == 33) {
                  final content = utf8.decode(bytes, allowMalformed: true);
                  if (content.contains(termuxUsrPrefix) ||
                      content.contains(termuxHomePrefix)) {
                    final newContent = content
                        .replaceAll(termuxUsrPrefix, prefixPath)
                        .replaceAll(termuxHomePrefix, homePath);
                    entity.writeAsStringSync(newContent);
                  }
                }
              }
            } catch (_) {}
          }
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
    final varDir = Directory(p.join(usrPath, 'var'));
    final etcDir = Directory(p.join(usrPath, 'etc'));
    final tmpDir = Directory(p.join(usrPath, 'tmp'));

    _applyFfiChmodRecursive(binDir, 493);
    _applyFfiChmodRecursive(libexecDir, 493);
    _applyFfiChmodRecursive(varDir, 493);
    _applyFfiChmodRecursive(etcDir, 493);
    _applyFfiChmodRecursive(tmpDir, 511);

    if (Platform.isAndroid) {
      try {
        final dirs = [binDir.path, libexecDir.path, varDir.path, etcDir.path]
            .where((p) => Directory(p).existsSync())
            .toList();
        if (dirs.isNotEmpty) {
          final joinedPaths = dirs.join('" "');
          await Process.run('/system/bin/sh', [
            '-c',
            '/system/bin/chmod -R 755 "$joinedPaths" 2>/dev/null || /system/bin/toybox chmod -R 755 "$joinedPaths" 2>/dev/null || chmod -R 755 "$joinedPaths" 2>/dev/null',
          ]);
        }
        if (await tmpDir.exists()) {
          await Process.run('/system/bin/sh', [
            '-c',
            '/system/bin/chmod 777 "${tmpDir.path}" 2>/dev/null || /system/bin/toybox chmod 777 "${tmpDir.path}" 2>/dev/null',
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
        if (await varDir.exists()) {
          await Process.run('chmod', ['-R', '755', varDir.path]);
        }
        if (await etcDir.exists()) {
          await Process.run('chmod', ['-R', '755', etcDir.path]);
        }
        if (await tmpDir.exists()) {
          await Process.run('chmod', ['777', tmpDir.path]);
        }
      } catch (_) {}
    }

    return true;
  }

  void _applyFfiChmodRecursive(Directory dir, [int mode = 493]) {
    try {
      if (!dir.existsSync()) return;
      _PosixChmod.chmod(dir.path, mode);
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        try {
          if (entity is Directory) {
            _PosixChmod.chmod(entity.path, mode);
          } else {
            _PosixChmod.chmod(entity.path, mode == 511 ? 511 : 493);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  String _findCaCertFile() {
    final candidates = [
      p.join(prefixPath, 'etc', 'tls', 'cert.pem'),
      p.join(prefixPath, 'etc', 'ssl', 'certs', 'ca-certificates.crt'),
      '/system/etc/security/cacerts',
    ];
    for (final cand in candidates) {
      if (File(cand).existsSync() || Directory(cand).existsSync()) {
        return cand;
      }
    }
    return p.join(prefixPath, 'etc', 'tls', 'cert.pem');
  }

  Map<String, String> getEnvironmentVariables({String? workingDirectory}) {
    final caBundle = _findCaCertFile();
    return {
      'PREFIX': prefixPath,
      'PATH': '$binPath:$binPath/applets:/system/bin:/system/xbin',
      'LD_LIBRARY_PATH': libPath,
      'HOME': homePath,
      'TMPDIR': tmpPath,
      'TERM': 'xterm-256color',
      'COLORTERM': 'truecolor',
      'LANG': 'en_US.UTF-8',
      'PWD': workingDirectory ?? homePath,
      'APT_CONFIG': p.join(prefixPath, 'etc', 'apt', 'apt.conf'),
      'DPKG_ADMINDIR': p.join(prefixPath, 'var', 'lib', 'dpkg'),
      'DPKG_DATADIR': p.join(prefixPath, 'share', 'dpkg'),
      'SSL_CERT_FILE': caBundle,
      'CURL_CA_BUNDLE': caBundle,
      'GIT_SSL_CAINFO': caBundle,
      'RESOLV_CONF': p.join(prefixPath, 'etc', 'resolv.conf'),
      'PROOT_TMP_DIR': tmpPath,
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
        '-b',
        '$prefixPath:$prefixPath',
        '-b',
        '$tmpPath:/tmp',
        '-b',
        '${p.join(prefixPath, "etc", "resolv.conf")}:/etc/resolv.conf',
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
