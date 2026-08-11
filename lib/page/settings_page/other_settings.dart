import 'package:pure_music/core/design_tokens.dart';
import 'package:pure_music/core/preference.dart';
import 'package:pure_music/core/utils.dart';
import 'package:pure_music/component/settings_tile.dart';
import 'package:pure_music/native/bass/bass_output_device.dart';
import 'package:pure_music/play_service/audio_echo_log_recorder.dart';
import 'package:pure_music/play_service/play_service.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class ReplayGainControl extends StatefulWidget {
  const ReplayGainControl({super.key});

  @override
  State<ReplayGainControl> createState() => _ReplayGainControlState();
}

class _ReplayGainControlState extends State<ReplayGainControl> {
  final pref = AppPreference.instance.playbackPref;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      description: 'ReplayGain',
      action: Switch(
        value: pref.replayGainEnabled,
        onChanged: (value) async {
          setState(() => pref.replayGainEnabled = value);
          PlayService.instance.playbackService.setReplayGainEnabled(value);
          await AppPreference.instance.save();
        },
      ),
    );
  }
}

class AudioEchoLogRecordControl extends StatefulWidget {
  const AudioEchoLogRecordControl({super.key});

  @override
  State<AudioEchoLogRecordControl> createState() =>
      _AudioEchoLogRecordControlState();
}

class _AudioEchoLogRecordControlState extends State<AudioEchoLogRecordControl> {
  final recorder = AudioEchoLogRecorder.instance;
  bool _isChangingRecording = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRecording = recorder.isRecording;
    final isBusy = _isChangingRecording;
    final statusLabel = isBusy
        ? isRecording
            ? '正在停止'
            : '正在开启'
        : isRecording
            ? '录制中'
            : '未开启';

    return SettingsTile(
      description: '回声排查日志录制',
      action: Wrap(
        spacing: 4.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            height: 32.0,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: isRecording
                  ? scheme.tertiaryContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: AppRadius.mdCircular,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isBusy)
                  SizedBox(
                    width: 14.0,
                    height: 14.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: isRecording
                          ? scheme.onTertiaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  )
                else
                  Icon(
                    isRecording ? Symbols.radio_button_checked : Symbols.circle,
                    size: 14.0,
                    color: isRecording
                        ? scheme.onTertiaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                const SizedBox(width: 6.0),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: isRecording
                        ? scheme.onTertiaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '写入快照',
            onPressed: isRecording && !isBusy
                ? () async {
                    recorder.snapshot(tag: 'manual');
                    await recorder.flush();
                    if (!context.mounted) return;
                    showTextOnSnackBar('已写入快照');
                  }
                : null,
            icon: const Icon(Symbols.bookmark),
          ),
          IconButton(
            tooltip: '打开日志目录',
            onPressed: () async {
              final opened = await recorder.openLogDir();
              if (!context.mounted) return;
              showTextOnSnackBar(opened ? '已打开日志目录' : '日志目录打开失败');
            },
            icon: const Icon(Symbols.folder),
          ),
          Switch(
            value: isRecording,
            onChanged: isBusy
                ? null
                : (v) async {
                    setState(() => _isChangingRecording = true);
                    try {
                      if (v) {
                        await recorder.start();
                      } else {
                        await recorder.stop();
                      }
                    } catch (_) {
                      if (mounted) {
                        showTextOnSnackBar(v ? '日志录制启动失败' : '日志录制停止失败');
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isChangingRecording = false);
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class AudioOutputDeviceControl extends StatefulWidget {
  const AudioOutputDeviceControl({super.key});

  @override
  State<AudioOutputDeviceControl> createState() =>
      _AudioOutputDeviceControlState();
}

class _AudioOutputDeviceControlState extends State<AudioOutputDeviceControl> {
  bool _busy = false;
  List<BassOutputDevice> _devices = const [];
  String _label = '系统默认';

  @override
  void initState() {
    super.initState();
    final deviceId = PlayService.instance.playbackService.outputDeviceId;
    _label = deviceId == -1 ? '系统默认' : '设备 $deviceId';
  }

  void _refreshDevices() {
    try {
      final playback = PlayService.instance.playbackService;
      _devices = playback.listOutputDevices();
      _label = _labelFor(playback.outputDeviceId, _devices);
    } catch (err, trace) {
      logger.w('[settings] refresh output devices failed',
          error: err, stackTrace: trace);
      _devices = const [];
      _label = '系统默认';
    }
    if (mounted) setState(() {});
  }

  String _labelFor(int deviceId, List<BassOutputDevice> devices) {
    if (deviceId == -1) return '系统默认';
    for (final device in devices) {
      if (device.id == deviceId) return device.label;
    }
    return '设备 $deviceId';
  }

  Future<void> _pickDevice() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final playback = PlayService.instance.playbackService;
      final devices = playback.listOutputDevices();
      if (devices.isNotEmpty) _devices = devices;
      if (!mounted) return;
      final currentId = playback.outputDeviceId;
      final selected = await showDialog<int>(
        context: context,
        builder: (context) => _OutputDevicePicker(
          devices: devices,
          currentId: currentId,
        ),
      );
      if (!mounted || selected == null || selected == currentId) return;
      final ok = playback.setOutputDevice(selected);
      if (!mounted) return;
      if (ok) {
        _refreshDevices();
        showTextOnSnackBar('已切换输出设备');
      } else {
        showTextOnSnackBar('切换输出设备失败', variant: ToastVariant.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SettingsTile(
      description: '播放设备',
      subtitle: '切换后正在播放的曲目会短暂中断并恢复',
      action: OutlinedButton(
        onPressed: _busy ? null : _pickDevice,
        child: _busy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              )
            : Text(
                _label,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}

class _OutputDevicePicker extends StatelessWidget {
  const _OutputDevicePicker({
    required this.devices,
    required this.currentId,
  });

  final List<BassOutputDevice> devices;
  final int currentId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      child: SizedBox(
        width: 480,
        height: 520,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '选择播放设备',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: AppType.sectionTitle,
                  fontWeight: AppType.weightBold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length + 1,
                  itemExtent: 56,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      const id = -1;
                      final selected = currentId == id;
                      return ListTile(
                        selected: selected,
                        selectedTileColor:
                            scheme.secondaryContainer.withValues(alpha: 0.45),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdCircular,
                        ),
                        leading: Icon(
                          selected ? Symbols.check_circle : Symbols.speaker,
                          color: selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        title: const Text('系统默认'),
                        trailing: selected ? const Icon(Symbols.check) : null,
                        onTap: selected
                            ? null
                            : () => Navigator.pop(context, id),
                      );
                    }
                    final device = devices[index - 1];
                    final selected = device.id == currentId;
                    return ListTile(
                      selected: selected,
                      selectedTileColor:
                          scheme.secondaryContainer.withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mdCircular,
                      ),
                      leading: Icon(
                        selected ? Symbols.check_circle : Symbols.speaker,
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      title: Text(
                        device.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: selected ? const Icon(Symbols.check) : null,
                      onTap: selected
                          ? null
                          : () => Navigator.pop(context, device.id),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
