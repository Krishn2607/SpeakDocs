import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceService {
  final AudioRecorder _recorder = AudioRecorder();

  // ============================================================
  // START RECORDING
  // ============================================================

  Future<void> startRecording() async {
    final bool hasPermission = await _recorder.hasPermission();

    if (!hasPermission) {
      throw Exception('Microphone permission is required for voice search.');
    }

    final Directory tempDirectory = await getTemporaryDirectory();

    final String filePath =
        '${tempDirectory.path}/speakdocs_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: filePath);
  }

  // ============================================================
  // STOP RECORDING
  // ============================================================

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  // ============================================================
  // CANCEL RECORDING
  // ============================================================

  Future<void> cancelRecording() async {
    await _recorder.cancel();
  }

  // ============================================================
  // DELETE TEMPORARY RECORDING
  // ============================================================

  Future<void> deleteRecording(String filePath) async {
    final File file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _recorder.dispose();
  }
}
