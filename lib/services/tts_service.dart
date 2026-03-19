import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

import '../models/course_model.dart';
import '../widgets/tts_download_dialog.dart';
import 'mms_tts_service.dart';
import 'mms_infer_service.dart';

/// Smart TTS service that tries the device's built-in TTS first.
/// If the course language is not available on the device, it shows a dialog
/// prompting the user to download the MMS TTS model for that language.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _flutterTts = FlutterTts();
  final Logger _logger = Logger();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MmsTtsService _mmsTtsService = MmsTtsService();
  final MmsInferService _mmsInferService = MmsInferService();

  bool _isInitialized = false;
  String? _loadedMmsLanguage;

  /// Cache of language availability results for the current session.
  /// Key: language code (as passed by the app), Value: true if device supports it.
  final Map<String, bool> _availabilityCache = {};

  /// Languages for which the user has already been shown the MMS dialog this session.
  final Set<String> _dialogShownFor = {};

  TtsService._internal() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      _logger.e('Failed to initialize TTS', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // Language code normalisation
  // ---------------------------------------------------------------------------

  /// Maps the app's language codes (ISO 639-1 or custom) to the BCP-47 locale
  /// strings expected by the device TTS engine.
  /// Falls through to the original code if no mapping is needed.
  static String toDeviceLocale(String appCode) {
    const Map<String, String> mappings = {
      // Short codes that need a region suffix for device TTS
      'af': 'af-ZA',
      'sq': 'sq-AL',
      'am': 'am-ET',
      'ar': 'ar-SA',
      'hy': 'hy-AM',
      'az': 'az-AZ',
      'eu': 'eu-ES',
      'be': 'be-BY',
      'bn': 'bn-BD',
      'bs': 'bs-BA',
      'bg': 'bg-BG',
      'my': 'my-MM',
      'ca': 'ca-ES',
      'hr': 'hr-HR',
      'cs': 'cs-CZ',
      'da': 'da-DK',
      'nl': 'nl-NL',
      'en': 'en-US',
      'et': 'et-EE',
      'fi': 'fi-FI',
      'fr': 'fr-FR',
      'gl': 'gl-ES',
      'ka': 'ka-GE',
      'de': 'de-DE',
      'el': 'el-GR',
      'gu': 'gu-IN',
      'he': 'he-IL',
      'hi': 'hi-IN',
      'hu': 'hu-HU',
      'is': 'is-IS',
      'id': 'id-ID',
      'ga': 'ga-IE',
      'it': 'it-IT',
      'ja': 'ja-JP',
      'kn': 'kn-IN',
      'kk': 'kk-KZ',
      'km': 'km-KH',
      'ko': 'ko-KR',
      'lo': 'lo-LA',
      'lv': 'lv-LV',
      'lt': 'lt-LT',
      'mk': 'mk-MK',
      'ms': 'ms-MY',
      'ml': 'ml-IN',
      'mt': 'mt-MT',
      'mr': 'mr-IN',
      'mn': 'mn-MN',
      'ne': 'ne-NP',
      'nb': 'nb-NO',
      'or': 'or-IN',
      'fa': 'fa-IR',
      'pl': 'pl-PL',
      'pa': 'pa-IN',
      'ro': 'ro-RO',
      'ru': 'ru-RU',
      'sr': 'sr-RS',
      'si': 'si-LK',
      'sk': 'sk-SK',
      'sl': 'sl-SI',
      'so': 'so-SO',
      'es': 'es-ES',
      'sw': 'sw-KE',
      'sv': 'sv-SE',
      'tg': 'tg-TJ',
      'ta': 'ta-IN',
      'te': 'te-IN',
      'th': 'th-TH',
      'tr': 'tr-TR',
      'uk': 'uk-UA',
      'ur': 'ur-PK',
      'uz': 'uz-UZ',
      'vi': 'vi-VN',
      'cy': 'cy-GB',
      'zu': 'zu-ZA',
      'fil': 'fil-PH',
      'jv': 'jv-ID',
      'su': 'su-ID',
      'mi': 'mi-NZ',
      'ky': 'ky-KG',
    };
    return mappings[appCode] ?? appCode;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> speak(
    String text, {
    required String languageCode,
    BuildContext? context,
    String? languageName,
    double? rate,
  }) async {
    if (!_isInitialized) await _initTts();
    if (text.trim().isEmpty) return;

    try {
      final deviceLocale = toDeviceLocale(languageCode);
      final available = await _isLanguageAvailable(deviceLocale);

      if (available) {
        await _flutterTts.setLanguage(deviceLocale);
        if (rate != null) {
          await _flutterTts.setSpeechRate(rate * 0.5); // Normalized for flutter_tts
        } else {
          await _flutterTts.setSpeechRate(0.5);
        }
        await _flutterTts.speak(text);
        return;
      }

      // If not available natively, check for MMS model
      if (await _mmsTtsService.isModelDownloaded(languageCode)) {
        await _speakWithMms(text, languageCode);
        return;
      }

      // Otherwise, show download dialog if context is available
      _logger.w('Device TTS and MMS model not available for: $languageCode');
      if (context != null && context.mounted && !_dialogShownFor.contains(languageCode)) {
        _dialogShownFor.add(languageCode);
        final resolvedName = languageName ??
            LanguageModel.getByCode(languageCode)?.name ??
            languageCode;
        showMmsTtsDownloadDialog(
          context,
          languageCode: languageCode,
          languageName: resolvedName,
        );
      }
    } catch (e) {
      _logger.e('Error speaking text', error: e);
    }
  }

  Future<void> _speakWithMms(String text, String languageCode) async {
    try {
      if (_loadedMmsLanguage != languageCode) {
        final onnxFile = await _mmsTtsService.getOnnxFile(languageCode);
        final tokensFile = await _mmsTtsService.getTokensFile(languageCode);
        await _mmsInferService.loadModel(onnxFile, tokensFile);
        _loadedMmsLanguage = languageCode;
      }

      final waveform = await _mmsInferService.synthesizeText(text);
      
      // Convert Float32 PCM to WAV bytes
      final wavBytes = _createWavHeader(waveform, 16000); // MMS models use 16kHz
      
      // Write to temp file for playback
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/mms_speech.wav');
      await tempFile.writeAsBytes(wavBytes);
      
      await _audioPlayer.setFilePath(tempFile.path);
      await _audioPlayer.play();
    } catch (e) {
      _logger.e('MMS Inference/Playback failed', error: e);
    }
  }

  /// Simple WAV header helper for mono Float32 audio
  Uint8List _createWavHeader(Float32List waveform, int sampleRate) {
    // Convert Float32 to 16-bit PCM (Int16)
    final Int16List pcmData = Int16List(waveform.length);
    for (int i = 0; i < waveform.length; i++) {
      pcmData[i] = (waveform[i] * 32767).clamp(-32768, 32767).toInt();
    }
    
    final int byteCount = pcmData.length * 2;
    final ByteData header = ByteData(44);

    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, 36 + byteCount, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    // fmt chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // space
    header.setUint32(16, 16, Endian.little); // chunk size
    header.setUint16(20, 1, Endian.little); // PCM format
    header.setUint16(22, 1, Endian.little); // Channels (mono)
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    header.setUint16(32, 2, Endian.little); // block align
    header.setUint16(34, 16, Endian.little); // bits per sample

    // data chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, byteCount, Endian.little);

    final Uint8List wav = Uint8List(44 + byteCount);
    wav.setAll(0, header.buffer.asUint8List());
    wav.setAll(44, pcmData.buffer.asUint8List());
    return wav;
  }

  /// Stops any ongoing speech.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      await _audioPlayer.stop();
    } catch (e) {
      _logger.e('Error stopping TTS', error: e);
    }
  }

  /// Clears the session cache so availability is re-checked.
  void clearCache() {
    _availabilityCache.clear();
    _dialogShownFor.clear();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<bool> _isLanguageAvailable(String deviceLocale) async {
    if (_availabilityCache.containsKey(deviceLocale)) {
      return _availabilityCache[deviceLocale]!;
    }

    try {
      final result = await _flutterTts.isLanguageAvailable(deviceLocale);
      // flutter_tts returns 1 or true when available
      final available = result == 1 || result == true;
      _availabilityCache[deviceLocale] = available;
      return available;
    } catch (e) {
      _logger.e('Failed to check language availability for $deviceLocale', error: e);
      // On error, assume available to avoid blocking TTS entirely
      _availabilityCache[deviceLocale] = true;
      return true;
    }
  }
}
