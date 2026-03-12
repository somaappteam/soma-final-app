import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class RawAudioSource extends StreamAudioSource {
  final Uint8List _buffer;

  RawAudioSource(this._buffer);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _buffer.length;
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_buffer.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}

class MmsAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  /// Converts a Float32List (from ONNX) into a valid WAV file byte array and plays it via just_audio
  Future<void> playFloat32Waveform(Float32List waveform) async {
    try {
      // 1. Convert float32 array (-1.0 to 1.0) to 16-bit PCM Int16
      final int16Data = Int16List(waveform.length);
      for (int i = 0; i < waveform.length; i++) {
        // Scale and clamp
        double val = waveform[i] * 32767.0;
        if (val > 32767) val = 32767;
        if (val < -32768) val = -32768;
        int16Data[i] = val.toInt();
      }

      // 2. Build WAV Header
      final bytes = Uint8List(44 + int16Data.lengthInBytes);
      final byteData = ByteData.view(bytes.buffer);

      // "RIFF"
      byteData.setUint32(0, 0x52494646, Endian.big);
      // File size
      byteData.setUint32(4, 36 + int16Data.lengthInBytes, Endian.little);
      // "WAVE"
      byteData.setUint32(8, 0x57415645, Endian.big);
      // "fmt "
      byteData.setUint32(12, 0x666D7420, Endian.big);
      // Subchunk1Size (16 for PCM)
      byteData.setUint32(16, 16, Endian.little);
      // AudioFormat (1 for PCM)
      byteData.setUint16(20, 1, Endian.little);
      // NumChannels (1 for mono MMS)
      byteData.setUint16(22, 1, Endian.little);
      // SampleRate (16000 for MMS)
      byteData.setUint32(24, 16000, Endian.little);
      // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
      byteData.setUint32(28, 16000 * 1 * 2, Endian.little);
      // BlockAlign (NumChannels * BitsPerSample/8)
      byteData.setUint16(32, 2, Endian.little);
      // BitsPerSample (16)
      byteData.setUint16(34, 16, Endian.little);
      // "data"
      byteData.setUint32(36, 0x64617461, Endian.big);
      // Subchunk2Size (data size)
      byteData.setUint32(40, int16Data.lengthInBytes, Endian.little);

      // 3. Write PCM data
      final dataView = Uint8List.view(int16Data.buffer);
      bytes.setAll(44, dataView);

      // 4. Play using just_audio custom source
      final source = RawAudioSource(bytes);
      await _player.setAudioSource(source);
      await _player.play();
      
    } catch (e) {
      debugPrint("Error playing MMS waveform: \$e");
    }
  }

  void dispose() {
    _player.dispose();
  }
}
