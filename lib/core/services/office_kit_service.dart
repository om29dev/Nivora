import 'dart:async';
import 'package:flutter/services.dart';

enum OfficeKitStatus {
  disconnected,
  searching,
  connected,
  paired,
}

class OfficeKitDeviceInfo {
  final String name;
  final String ipAddress;
  final String os;
  final bool hasComputeAcceleration;

  const OfficeKitDeviceInfo({
    required this.name,
    required this.ipAddress,
    required this.os,
    this.hasComputeAcceleration = true,
  });
}

class OfficeKitService {
  OfficeKitStatus _status = OfficeKitStatus.disconnected;
  OfficeKitDeviceInfo? _connectedDevice;
  final _statusController = StreamController<OfficeKitStatus>.broadcast();

  OfficeKitStatus get status => _status;
  OfficeKitDeviceInfo? get connectedDevice => _connectedDevice;
  Stream<OfficeKitStatus> get statusStream => _statusController.stream;

  Future<void> startDiscovery() async {
    _status = OfficeKitStatus.searching;
    _statusController.add(_status);

    // Simulate LAN broadcast discovery
    await Future.delayed(const Duration(milliseconds: 800));

    _connectedDevice = const OfficeKitDeviceInfo(
      name: 'Developer Laptop (MacBook Pro / ThinkPad)',
      ipAddress: '192.168.1.145',
      os: 'macOS / Linux / Windows',
      hasComputeAcceleration: true,
    );
    _status = OfficeKitStatus.connected;
    _statusController.add(_status);
  }

  Future<bool> syncClipboard(String text) async {
    if (_status != OfficeKitStatus.connected) return false;
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  }

  Future<void> disconnect() async {
    _status = OfficeKitStatus.disconnected;
    _connectedDevice = null;
    _statusController.add(_status);
  }
}
