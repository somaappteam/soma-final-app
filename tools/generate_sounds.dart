import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final dir = Directory('assets/sounds');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  generateWavFile('assets/sounds/correct.wav', generateCorrectSound());
  generateWavFile('assets/sounds/wrong.wav', generateWrongSound());
  
  print('Sound files generated successfully.');
}

void generateWavFile(String path, List<int> samples) {
  final file = File(path);
  final header = _buildWavHeader(samples.length);
  final builder = BytesBuilder();
  builder.add(header);
  
  for (final sample in samples) {
    builder.addByte(sample & 0xff);
    builder.addByte((sample >> 8) & 0xff);
  }
  
  file.writeAsBytesSync(builder.toBytes());
}

Uint8List _buildWavHeader(int sampleCount) {
  final byteCount = sampleCount * 2; // 16-bit = 2 bytes per sample
  const headerInfoSize = 36;
  final fileLength = headerInfoSize + byteCount;

  final header = Uint8List(44);
  final byteData = ByteData.view(header.buffer);

  // "RIFF"
  header[0] = 82; header[1] = 73; header[2] = 70; header[3] = 70;
  byteData.setUint32(4, fileLength, Endian.little);
  // "WAVE"
  header[8] = 87; header[9] = 65; header[10] = 86; header[11] = 69;
  // "fmt "
  header[12] = 102; header[13] = 109; header[14] = 116; header[15] = 32;
  // Subchunk1Size (16 for PCM)
  byteData.setUint32(16, 16, Endian.little);
  // AudioFormat (1 for PCM)
  byteData.setUint16(20, 1, Endian.little);
  // NumChannels
  byteData.setUint16(22, 1, Endian.little);
  // SampleRate (44100)
  byteData.setUint32(24, 44100, Endian.little);
  // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
  byteData.setUint32(28, 44100 * 2, Endian.little);
  // BlockAlign
  byteData.setUint16(32, 2, Endian.little);
  // BitsPerSample
  byteData.setUint16(34, 16, Endian.little);
  // "data"
  header[36] = 100; header[37] = 97; header[38] = 116; header[39] = 97;
  byteData.setUint32(40, byteCount, Endian.little);

  return header;
}

List<int> generateCorrectSound() {
  const sampleRate = 44100;
  const durationSec = 0.3;
  final numSamples = (sampleRate * durationSec).toInt();
  final samples = <int>[];

  // A nice ascending chime (C6, E6, G6)
  final freqs = [1046.50, 1318.51, 1567.98];
  
  for (int i = 0; i < numSamples; i++) {
    double t = i / sampleRate;
    double sample = 0;
    
    // Envelope (fast attack, exponential decay)
    double env = exp(-t * 15);
    
    // Mix frequencies
    int fIndex = (t * 10).floor().clamp(0, 2);
    sample += sin(2 * pi * freqs[fIndex] * t);
    sample += sin(2 * pi * freqs[fIndex] * 2 * t) * 0.3; // harmonics
    
    sample *= env;
    
    int val = (sample * 16000).toInt().clamp(-32768, 32767);
    samples.add(val);
  }
  return samples;
}

List<int> generateWrongSound() {
  const sampleRate = 44100;
  const durationSec = 0.4;
  final numSamples = (sampleRate * durationSec).toInt();
  final samples = <int>[];

  // A low buzzer (two descending tones)
  for (int i = 0; i < numSamples; i++) {
    double t = i / sampleRate;
    double sample = 0;
    
    // Envelope
    double env = exp(-t * 8);
    
    // Frequency drops slightly over time
    double freq = t < 0.2 ? 220 : 190;
    
    // Sawtooth-like wave
    sample = (2 * ((t * freq) - (t * freq).floor()) - 1) * 0.5;
    
    sample *= env;
    
    int val = (sample * 16000).toInt().clamp(-32768, 32767);
    samples.add(val);
  }
  return samples;
}
