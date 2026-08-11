import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pure_music/native/rust/api/system_volume.dart';

class SystemVolumeService {
  SystemVolumeService._();

  static SystemVolumeService? _instance;
  static SystemVolumeService get instance {
    _instance ??= SystemVolumeService._();
    return _instance!;
  }

  final volume = ValueNotifier<double>(0.5);

  bool _bound = false;
  StreamSubscription<double>? _volumeSub;
  bool _dragging = false;
  bool _setting = false;
  double? _pendingSet;

  void ensureBound() {
    if (_bound) return;
    _bound = true;
    try {
      volume.value = systemVolumeGet().clamp(0.0, 1.0);
    } catch (_) {}
    _volumeSub = systemVolumeInit().listen(
      (v) {
        if (_dragging) return;
        final next = v.clamp(0.0, 1.0);
        if ((next - volume.value).abs() > 0.0001) {
          volume.value = next;
        }
      },
      onError: (_) {},
    );
  }

  Future<double?> read({required Duration timeout}) async {
    try {
      return await Future<double>.value(systemVolumeGet())
          .timeout(timeout)
          .then((v) => v.clamp(0.0, 1.0));
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh({required Duration timeout}) async {
    final v = await read(timeout: timeout);
    if (v != null && (v - volume.value).abs() > 0.0001) {
      volume.value = v;
    }
  }

  void beginDrag() => _dragging = true;

  void endDrag() {
    _dragging = false;
    refresh(timeout: const Duration(milliseconds: 400));
  }

  Future<void> set(double v) async {
    _pendingSet = v.clamp(0.0, 1.0);
    if (_setting) return;
    _setting = true;
    while (_pendingSet != null) {
      final next = _pendingSet!;
      _pendingSet = null;
      try {
        systemVolumeSet(val: next);
      } catch (_) {}
    }
    _setting = false;
  }

  void dispose() {
    _volumeSub?.cancel();
    _volumeSub = null;
    if (_bound) {
      try {
        systemVolumeDispose();
      } catch (_) {}
      _bound = false;
    }
    volume.dispose();
    _instance = null;
  }
}
