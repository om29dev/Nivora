import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivora/core/services/termux_environment_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TermuxEnvironmentService Tests', () {
    late Directory tempDir;
    late TermuxEnvironmentService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('nivora_termux_test_');
      service = TermuxEnvironmentService();
      await service.initialize(customBasePath: tempDir.path);
    });

    tearDown(() async {
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    test('Initializes paths correctly under custom base path', () {
      expect(service.prefixPath, equals(p.join(tempDir.path, 'usr')));
      expect(service.binPath, equals(p.join(tempDir.path, 'usr', 'bin')));
      expect(service.libPath, equals(p.join(tempDir.path, 'usr', 'lib')));
      expect(service.homePath, equals(p.join(tempDir.path, 'home')));
      expect(service.tmpPath, equals(p.join(tempDir.path, 'usr', 'tmp')));
      expect(service.status, equals(TermuxEnvironmentStatus.uninstalled));
    });

    test('Detects architecture successfully', () async {
      final arch = await service.detectArchitecture();
      expect(['aarch64', 'arm', 'x86_64', 'i686'].contains(arch), isTrue);
    });

    test('Generates complete POSIX environment variables with Termux paths', () {
      final env = service.getEnvironmentVariables(workingDirectory: '/test/workspace');

      expect(env['PREFIX'], equals(service.prefixPath));
      expect(env['PATH'], contains(service.binPath));
      expect(env['LD_LIBRARY_PATH'], equals(service.libPath));
      expect(env['HOME'], equals(service.homePath));
      expect(env['TMPDIR'], equals(service.tmpPath));
      expect(env['TERM'], equals('xterm-256color'));
      expect(env['PWD'], equals('/test/workspace'));
    });

    test('Parses SYMLINKS.txt format correctly', () async {
      final usrDir = Directory(p.join(tempDir.path, 'usr'));
      final binDir = Directory(p.join(usrDir.path, 'bin'));
      await binDir.create(recursive: true);

      // Create dummy target file
      final bashFile = File(p.join(binDir.path, 'bash'));
      await bashFile.writeAsString('#!/bin/sh\necho ok');

      const symlinksData = 'bash←bin/sh\n';
      await TermuxEnvironmentService.processSymlinks(symlinksData, usrDir.path);

      final linkOrFile = File(p.join(usrDir.path, 'bin', 'sh'));
      expect(await linkOrFile.exists() || await Link(linkOrFile.path).exists(), isTrue);
    });

    test('PRoot wrapper wraps commands with com.termux remapping', () async {
      // Simulate proot binary presence
      final binDir = Directory(service.binPath);
      await binDir.create(recursive: true);
      final proot = File(service.prootBinaryPath);
      await proot.writeAsString('mock proot');

      final wrapped = service.wrapCommandWithProot(
        command: 'pkg install nodejs',
        workingDirectory: '/data/projects/my-app',
      );

      expect(wrapped.first, equals(service.prootBinaryPath));
      expect(wrapped.contains('-b'), isTrue);
      expect(wrapped.any((arg) => arg.contains('/data/data/com.termux/files/usr')), isTrue);
      expect(wrapped.last, equals('pkg install nodejs'));
    });

    test('ensureBinariesExecutable completes without throwing', () async {
      final binDir = Directory(service.binPath);
      await binDir.create(recursive: true);
      final bash = File(service.bashBinaryPath);
      await bash.writeAsString('#!/bin/sh\necho test');

      final result = await service.ensureBinariesExecutable();
      expect(result, isTrue);
    });
  });
}
