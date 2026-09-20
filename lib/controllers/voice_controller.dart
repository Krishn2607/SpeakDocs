import '../services/voice_service.dart';

class VoiceController {
  final VoiceService _voiceService;

  VoiceController({VoiceService? voiceService})
    : _voiceService = voiceService ?? VoiceService();

  bool isRecording = false;

  Future<void> startRecording() async {
    if (isRecording) {
      return;
    }

    await _voiceService.startRecording();

    isRecording = true;
  }

  Future<String> stopAndTranscribe() async {
    if (!isRecording) {
      throw Exception('Voice recording is not active.');
    }

    String? filePath;

    try {
      filePath = await _voiceService.stopRecording();

      isRecording = false;

      if (filePath == null || filePath.isEmpty) {
        throw Exception('No recording was captured.');
      }

      try {
        return await _voiceService.transcribeRecording(filePath);
      } finally {
        await _voiceService.deleteRecording(filePath);
      }
    } finally {
      isRecording = false;
    }
  }

  Future<void> cancelRecording() async {
    if (!isRecording) {
      return;
    }

    await _voiceService.cancelRecording();

    isRecording = false;
  }

  void dispose() {
    _voiceService.dispose();
  }
}
