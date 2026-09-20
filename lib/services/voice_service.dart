import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoiceService {
  final AudioRecorder _recorder = AudioRecorder();

  final SupabaseClient _supabase = Supabase.instance.client;

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

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
  }

  Future<String> transcribeRecording(String filePath) async {
    final firebase_auth.User? user =
        firebase_auth.FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('You must be logged in to use voice search.');
    }

    final String? idToken = await user.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Unable to authenticate voice search.');
    }

    final File audioFile = File(filePath);

    if (!await audioFile.exists()) {
      throw Exception('Recorded audio file was not found.');
    }

    final Uint8List audioBytes = await audioFile.readAsBytes();

    if (audioBytes.isEmpty) {
      throw Exception('Recorded audio file is empty.');
    }

    final response = await _supabase.functions.invoke(
      'transcribe-audio',
      body: audioBytes,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'audio/mp4',
      },
    );

    final dynamic data = response.data;

    if (data is! Map) {
      throw Exception('Invalid transcription response.');
    }

    final String text = data['text']?.toString().trim() ?? '';

    if (text.isEmpty) {
      throw Exception('No speech was detected.');
    }

    return text;
  }

  Future<void> deleteRecording(String filePath) async {
    final File file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}
