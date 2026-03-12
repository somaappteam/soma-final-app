import 'dart:io';
import 'package:flutter/foundation.dart';

class MmsTokenizer {
  final Map<String, int> _vocab = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Loads the vocabulary from a tokens.txt file
  Future<void> loadVocab(File vocabFile) async {
    try {
      if (!await vocabFile.exists()) {
        throw Exception('Vocabulary file not found at ${vocabFile.path}');
      }

      final lines = await vocabFile.readAsLines();
      _vocab.clear();

      for (var line in lines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final token = parts[0];
          final id = int.tryParse(parts[1]);
          if (id != null) {
            _vocab[token] = id;
          }
        }
      }
      _isLoaded = true;
      debugPrint('Loaded MMS vocabulary: \${_vocab.length} tokens');
    } catch (e) {
      debugPrint('Error loading MMS vocab: \$e');
      rethrow;
    }
  }

  /// Tokenizes text into the integer array required by VITS.
  /// MMS models use interspersing blank tokens (id 0) between characters.
  List<int> tokenize(String text) {
    if (!_isLoaded) {
      throw Exception('Vocabulary is not loaded yet.');
    }

    // Default blank token
    const int blankId = 0;
    
    // Convert to lowercase as MMS models are mostly lowercase character-based
    final cleanText = text.toLowerCase();
    
    final List<int> sequence = [];
    sequence.add(blankId); // Always start with a blank

    for (int i = 0; i < cleanText.length; i++) {
      final char = cleanText[i];
      
      // Look up character
      if (_vocab.containsKey(char)) {
        sequence.add(_vocab[char]!);
        sequence.add(blankId);
      } else if (char == ' ' && _vocab.containsKey('<space>')) {
        sequence.add(_vocab['<space>']!);
        sequence.add(blankId);
      } else {
        // Unknown character - skip or add UNK if vocab has it
        if (_vocab.containsKey('<unk>')) {
           sequence.add(_vocab['<unk>']!);
           sequence.add(blankId);
        }
      }
    }

    return sequence;
  }
}
