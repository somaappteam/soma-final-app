import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class MmsTtsService {

  /// Returns the local directory where the models for [languageCode] are stored.
  Future<Directory> _getModelDir(String languageCode) async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDir.path}/mms_models/$languageCode');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  /// Checks if the ONNX model and tokens.txt for a given [languageCode] exist locally.
  Future<bool> isModelDownloaded(String languageCode) async {
    final dir = await _getModelDir(languageCode);
    final onnxFile = File('${dir.path}/model.onnx');
    final tokensFile = File('${dir.path}/tokens.txt');
    
    return await onnxFile.exists() && await tokensFile.exists();
  }

  /// Downloads the ONNX model and tokens.txt for [languageCode].
  /// [onProgress] returns a value between 0.0 and 1.0
  Future<void> downloadModel(String languageCode, {Function(double)? onProgress}) async {
    final mmsCode = _toMmsCode(languageCode);
    try {
      if (await isModelDownloaded(languageCode)) {
        debugPrint("Model already downloaded for $languageCode ($mmsCode).");
        onProgress?.call(1.0);
        return;
      }

      final dir = await _getModelDir(languageCode);
      final onnxFile = File('${dir.path}/model.onnx');
      final tokensFile = File('${dir.path}/tokens.txt');

      debugPrint("Downloading TTS Model for $languageCode ($mmsCode) from HuggingFace...");
      
      // Download ONNX (vast majority of size)
      await _downloadWithProgress(mmsCode, 'model.onnx', onnxFile, (p) {
        // Map 0-1 to 0-0.99 for the first file
        onProgress?.call(p * 0.99);
      });
      
      // Download tokens
      await _downloadWithProgress(mmsCode, 'tokens.txt', tokensFile, (p) {
        // Map 0-1 to 0.99-1.0
        onProgress?.call(0.99 + (p * 0.01));
      });
      
      debugPrint("TTS Model for $languageCode successfully downloaded.");
    } catch (e) {
      debugPrint("Error downloading TTS model for $languageCode ($mmsCode): $e");
      rethrow;
    }
  }

  static const String _baseUrl = 'https://huggingface.co/willwade/mms-tts-multilingual-models-onnx/resolve/main/';

  Future<void> _downloadWithProgress(String mmsCode, String fileName, File destFile, Function(double) onProgress) async {
    final url = '$_baseUrl$mmsCode/$fileName';
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = true;
      request.headers.add('User-Agent', 'SomaApp/1.0 (Flutter)');
      
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Failed to download $url: ${response.statusCode} ${response.reasonPhrase}');
      }
      
      final contentLength = response.contentLength;
      int downloadedBytes = 0;
      
      final IOSink sink = destFile.openWrite();
      await for (var chunk in response) {
        downloadedBytes += chunk.length;
        sink.add(chunk);
        if (contentLength > 0) {
          onProgress(downloadedBytes / contentLength);
        }
      }
      await sink.close();
    } finally {
      client.close();
    }
  }


  /// Corrects language codes for MMS models (usually 3-letter ISO codes)
  String _toMmsCode(String code) {
    // Basic mapping for common mismatched codes
    final Map<String, String> mapping = {
      'rw': 'kin', // Kinyarwanda
      'am': 'amh', // Amharic
      'af': 'afr', // Afrikaans
      'sq': 'sqi', // Albanian
      'as': 'asm', // Assamese
      'bm': 'bam', // Bambara
      'bn': 'ben', // Bengali
      'bg': 'bul', // Bulgarian
      'my': 'mya', // Burmese
      'ca': 'cat', // Catalan
      'ny': 'nya', // Chichewa
      'hr': 'hrv', // Croatian
      'cs': 'ces', // Czech
      'da': 'dan', // Danish
      'nl': 'nld', // Dutch
      'eo': 'epo', // Esperanto
      'et': 'est', // Estonian
      'ee': 'ewe', // Ewe
      'fil': 'tgl', // Tagalog/Filipino
      'fi': 'fin', // Finnish
      'fr': 'fra', // French
      'gl': 'glg', // Galician
      'ka': 'kat', // Georgian
      'de': 'deu', // German
      'el': 'ell', // Greek
      'gu': 'guj', // Gujarati
      'ht': 'hat', // Haitian Creole
      'ha': 'hau', // Hausa
      'he': 'heb', // Hebrew
      'hi': 'hin', // Hindi
      'hu': 'hun', // Hungarian
      'is': 'isl', // Icelandic
      'ig': 'ibo', // Igbo
      'id': 'ind', // Indonesian
      'ga': 'gle', // Irish
      'it': 'ita', // Italian
      'ja': 'jpn', // Japanese
      'jv': 'jav', // Javanese
      'kn': 'kan', // Kannada
      'ks': 'kas', // Kashmiri
      'kk': 'kaz', // Kazakh
      'km': 'khm', // Khmer
      'ko': 'kor', // Korean
      'ku': 'kur', // Kurdish
      'ky': 'kir', // Kyrgyz
      'lo': 'lao', // Lao
      'la': 'lat', // Latin
      'lv': 'lav', // Latvian
      'lt': 'lit', // Lithuanian
      'lg': 'lug', // Luganda
      'mk': 'mkd', // Macedonian
      'mg': 'mlg', // Malagasy
      'ms': 'zlm', // Malay
      'ml': 'mal', // Malayalam
      'mt': 'mlt', // Maltese
      'mr': 'mar', // Marathi
      'mn': 'mon', // Mongolian
      'ne': 'nep', // Nepali
      'or': 'ory', // Odia
      'ps': 'pus', // Pashto
      'fa': 'fas', // Persian
      'pl': 'pol', // Polish
      'ro': 'ron', // Romanian
      'ru': 'rus', // Russian
      'sa': 'san', // Sanskrit
      'sr': 'srp', // Serbian
      'sn': 'sna', // Shona
      'sd': 'snd', // Sindhi
      'si': 'sin', // Sinhala
      'sk': 'slk', // Slovak
      'sl': 'slv', // Slovenian
      'so': 'som', // Somali
      'su': 'sun', // Sundanese
      'sw': 'swh', // Swahili
      'sv': 'swe', // Swedish
      'tg': 'tgk', // Tajik
      'ta': 'tam', // Tamil
      'tt': 'tat', // Tatar
      'te': 'tel', // Telugu
      'th': 'tha', // Thai
      'ti': 'tir', // Tigrinya
      'tr': 'tur', // Turkish
      'uk': 'ukr', // Ukrainian
      'ur': 'urd', // Urdu
      'uz': 'uzb', // Uzbek
      'vi': 'vie', // Vietnamese
      'cy': 'cym', // Welsh
      'wo': 'wol', // Wolof
      'yi': 'yid', // Yiddish
      'yo': 'yor', // Yoruba
      'zu': 'zul', // Zulu
    };

    final cleanCode = code.split('-').first.split('_').first.toLowerCase();
    return mapping[cleanCode] ?? cleanCode;
  }

  /// Get paths for inference integration
  Future<File> getOnnxFile(String languageCode) async {
    final dir = await _getModelDir(languageCode);
    return File('${dir.path}/model.onnx');
  }

  Future<File> getTokensFile(String languageCode) async {
    final dir = await _getModelDir(languageCode);
    return File('${dir.path}/tokens.txt');
  }
}
