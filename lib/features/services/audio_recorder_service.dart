import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper around the `record` package for capturing voice notes.
///
/// Produces an `.m4a` (AAC) file in the app's temp dir, which is small and
/// plays back on both Android and iOS.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  DateTime? _startedAt;

  /// Elapsed recording time, or zero when idle.
  Duration get elapsed =>
      _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  /// Starts recording. Returns `null` on success, or an error message string
  /// describing why it could not start (so the UI can show it).
  Future<String?> start() async {
    try {
      // Ask explicitly via permission_handler first (more reliable across
      // OEM Android builds), then fall back to the package's own check.
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          return 'Microphone blocked. Enable it in Settings.';
        }
        return 'Microphone permission denied';
      }
      if (!await _recorder.hasPermission()) {
        return 'Microphone permission denied';
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _isRecording = true;
      _startedAt = DateTime.now();
      return null;
    } catch (e) {
      _isRecording = false;
      _startedAt = null;
      return 'Could not start recording: $e';
    }
  }

  /// Stops recording and returns the file path (or null if nothing recorded).
  Future<String?> stop() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;
    _startedAt = null;
    return path;
  }

  /// Cancels and discards the current recording.
  Future<void> cancel() async {
    if (!_isRecording) return;
    await _recorder.cancel();
    _isRecording = false;
    _startedAt = null;
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
