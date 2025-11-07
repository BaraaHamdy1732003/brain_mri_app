import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import '../utils/constants.dart';

class TFLiteService {
  Interpreter? _interpreter;
  List<String> labels = [];
  bool isQuantized = false;
  int inputSize = MODEL_INPUT_SIZE;

  Future<void> loadModelAndLabels() async {
    // Load interpreter
    try {
      _interpreter = await Interpreter.fromAsset(MODEL_PATH);
    } catch (e) {
      throw Exception('Failed to load model: $e');
    }

    // Load labels
    final rawLabels = await rootBundle.loadString(LABELS_PATH);
    labels = rawLabels.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    // determine if input is quantized
    final inputTensor = _interpreter!.getInputTensor(0);
    isQuantized = inputTensor.type == TfLiteType.uint8 || inputTensor.type == TfLiteType.int8;
  }

  /// Run inference on an image file, returns predicted label and scores list
  Future<Map<String, dynamic>> runModelOnImage(File imageFile) async {
    if (_interpreter == null) await loadModelAndLabels();

    // Prepare image
    TensorImage tensorImage = isQuantized ? TensorImage(TfLiteType.uint8) : TensorImage(TfLiteType.float32);
    tensorImage.loadImage(imageFile);

    final ImageProcessor processor = ImageProcessorBuilder()
        .add(ResizeOp(inputSize, inputSize, ResizeMethod.BILINEAR))
        .build();
    tensorImage = processor.process(tensorImage);

    TensorBuffer inputBuffer = tensorImage.buffer;

    // Prepare output
    final outputTensor = _interpreter!.getOutputTensor(0);
    final outputShape = outputTensor.shape; // typically [1, numClasses]
    final outputType = outputTensor.type;
    final TensorBuffer outputBuffer = TensorBuffer.createFixedSize(outputShape, outputType);

    // Run inference
    _interpreter!.run(inputBuffer.buffer, outputBuffer.buffer);

    // Get output as floats (dequantize if necessary)
    List<double> outputs;
    if (outputBuffer.type == TfLiteType.uint8 || outputBuffer.type == TfLiteType.int8) {
      // Dequantize using quant params
      final quantParams = outputTensor.quantizationParameters;
      final scale = quantParams?.scales?[0] ?? 1.0;
      final zeroPoint = quantParams?.zeroPoints?[0] ?? 0;
      final uint8List = outputBuffer.getUint8List();
      outputs = uint8List.map((v) => (v - zeroPoint) * scale).map((e) => e.toDouble()).toList();
    } else {
      outputs = outputBuffer.getFloatList().map((e) => e.toDouble()).toList();
    }

    // Softmax to probabilities
    final probs = _softmax(outputs);

    // get best idx
    int best = 0;
    double bestVal = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > bestVal) {
        best = i;
        bestVal = probs[i];
      }
    }

    final predictedLabel = (labels.isNotEmpty && best < labels.length) ? labels[best] : best.toString();

    return {
      'predicted_label': predictedLabel,
      'labels': labels,
      'scores': probs,
    };
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    final exps = logits.map((l) => (l - maxLogit)).map((d) => MathExp.exp(d)).toList();
    final sumExps = exps.fold(0.0, (a, b) => a + b);
    return exps.map((e) => e / sumExps).toList();
  }
}

// tiny exp helper since dart:math exp uses import
class MathExp {
  static double exp(double x) => Math._exp(x);
}

// simple wrapper to call dart:math's exp (kept minimal)
import 'dart:math' as Math;
extension MathExpExt on Math {
  static double _exp(double x) => Math.exp(x);
}
