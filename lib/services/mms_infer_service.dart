import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'mms_tokenizer.dart';

class MmsInferService {
  OrtSessionOptions? _sessionOptions;
  OrtSession? _session;
  OrtRunOptions? _runOptions;
  
  final MmsTokenizer _tokenizer = MmsTokenizer();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    OrtEnv.instance.init();
    _sessionOptions = OrtSessionOptions();
    _runOptions = OrtRunOptions();
    debugPrint("ONNX Runtime initialized.");
  }

  /// Loads both the ONNX model and its associated tokens.txt vocabulary file.
  Future<void> loadModel(File onnxFile, File vocabFile) async {
    if (_sessionOptions == null) {
      await init();
    }
    
    try {
      if (!await onnxFile.exists()) {
        throw Exception('ONNX file not found at ${onnxFile.path}');
      }
      
      // Load vocabulary
      await _tokenizer.loadVocab(vocabFile);

      // Load Session
      final rawModelBytes = await onnxFile.readAsBytes();
      _session = OrtSession.fromBuffer(rawModelBytes, _sessionOptions!);
      
      _isInitialized = true;
      debugPrint("ONNX Session loaded successfully.");
    } catch (e) {
      debugPrint("Error loading ONNX model: \$e");
      rethrow;
    }
  }

  /// Synthesizes text into a raw Float32 audio waveform.
  /// Ensure [text] is provided.
  Future<Float32List> synthesizeText(String text) async {
    if (!_isInitialized || _session == null) {
      throw Exception('ONNX model is not loaded.');
    }

    try {
      // 1. Tokenize text mapping text -> IDs (int64)
      final tokenIds = _tokenizer.tokenize(text);
      
      // 2. Prepare inputs
      // x shape: [1, text_length]
      final xShape = [1, tokenIds.length];
      final xTensor = OrtValueTensor.createTensorWithDataList(
          Int64List.fromList(tokenIds), xShape);

      // x_length shape: [1]
      final xLengthShape = [1];
      final xLengthTensor = OrtValueTensor.createTensorWithDataList(
          Int64List.fromList([tokenIds.length]), xLengthShape);

      // noise_scale shape: [1] (0.667)
      final noiseScaleShape = [1];
      // Note: Dart ONNX package requires floating point bytes for creating from list
      // Creating simple list:
      final noiseScaleBuffer = Float32List.fromList([0.667]);
      final noiseScaleTensor = OrtValueTensor.createTensorWithDataList(
          noiseScaleBuffer, noiseScaleShape);

      // length_scale shape: [1] (1.0)
      final lengthScaleBuffer = Float32List.fromList([1.0]);
      final lengthScaleTensor = OrtValueTensor.createTensorWithDataList(
          lengthScaleBuffer, noiseScaleShape);

      // noise_scale_w shape: [1] (0.8)
      final noiseScaleWBuffer = Float32List.fromList([0.8]);
      final noiseScaleWTensor = OrtValueTensor.createTensorWithDataList(
          noiseScaleWBuffer, noiseScaleShape);

      // 3. Map inputs to graph names
      final inputs = {
        'x': xTensor,
        'x_length': xLengthTensor,
        'noise_scale': noiseScaleTensor,
        'length_scale': lengthScaleTensor,
        'noise_scale_w': noiseScaleWTensor,
      };

      // 4. Run Inference
      final outputs = _session!.run(_runOptions!, inputs);
      
      // 5. Extract audio waveform output 'y'
      final outputTensor = outputs[0]!.value as List<dynamic>;
      // Output shape is usually [1, 1, audio_length]
      final audioDynamicList = outputTensor[0][0] as List<dynamic>;
      
      // Cast down
      final Float32List waveform = Float32List(audioDynamicList.length);
      for (int i = 0; i < audioDynamicList.length; i++) {
        waveform[i] = audioDynamicList[i] as double;
      }

      // 6. Cleanup Tensors
      xTensor.release();
      xLengthTensor.release();
      noiseScaleTensor.release();
      lengthScaleTensor.release();
      noiseScaleWTensor.release();
      for (var out in outputs) {
        out?.release();
      }

      return waveform;
    } catch (e) {
      debugPrint("ONNX Inference Error: \$e");
      rethrow;
    }
  }

  void dispose() {
    _session?.release();
    _sessionOptions?.release();
    _runOptions?.release();
    OrtEnv.instance.release();
    _isInitialized = false;
  }
}
