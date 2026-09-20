import '../services/voice_service.dart';

class VoiceController {
  final VoiceService _voiceService;

  VoiceController({VoiceService? voiceService})
    : _voiceService = voiceService ?? VoiceService();

  // ============================================================
  // STATE
  // ============================================================

  bool isRecording = false;

  // ============================================================
  // START RECORDING
  // ============================================================

  Future<void> startRecording() async {
    if (isRecording) {
      return;
    }

    await _voiceService.startRecording();

    isRecording = true;
  }

  // ============================================================
  // STOP RECORDING
  // ============================================================

  Future<String?> stopRecording() async {
    if (!isRecording) {
      return null;
    }

    final String? filePath = await _voiceService.stopRecording();

    isRecording = false;

    return filePath;
  }

  // ============================================================
  // CANCEL RECORDING
  // ============================================================

  Future<void> cancelRecording() async {
    if (!isRecording) {
      return;
    }

    await _voiceService.cancelRecording();

    isRecording = false;
  }

  // ============================================================
  // DELETE RECORDING
  // ============================================================

  Future<void> deleteRecording(String filePath) async {
    await _voiceService.deleteRecording(filePath);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _voiceService.dispose();
  }
}
