
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'dart:typed_data';

class ClassifyScreen extends StatefulWidget {
  static const routeName = '/classify';

  const ClassifyScreen({super.key});

  @override
  State<ClassifyScreen> createState() => _ClassifyScreenState();
}

class _ClassifyScreenState extends State<ClassifyScreen> {
  String status = 'Idle';
  String? inputPath;
  List<String> labels = ['Unknown'];
  List<double> output = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    inputPath = ModalRoute.of(context)?.settings.arguments as String?;
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    try {
      final data = await DefaultAssetBundle.of(context).loadString('assets/labels.txt');
      setState(() {
        labels = data.split('\n').where((e) => e.trim().isNotEmpty).toList();
      });
    } catch (_) {
      // keep default
    }
  }

  Future<Float32List> _prepareMonoLogMel(String srcPath) async {
    // Decode to 16kHz mono WAV
    setState(() => status = 'Decoding for inference…');
    final dir = await getApplicationDocumentsDirectory();
    final wavOut = '${dir.path}/tmp_infer_${DateTime.now().millisecondsSinceEpoch}.wav';
    final cmd = "-y -i \"$srcPath\" -ac 1 -ar 16000 -f wav \"$wavOut\"";
    await FFmpegKit.execute(cmd);
    final file = File(wavOut);
    if (!await file.exists()) {
      throw Exception('Decode failed.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes <= 44) {
      throw Exception('WAV too short.');
    }
    final pcm = bytes.buffer.asInt16List(44);
    // Downsample/trim or pad to fixed length (e.g., 1 second = 16000 samples)
    const targetLen = 16000;
    final out = Float32List(targetLen);
    for (int i = 0; i < targetLen; i++) {
      final srcIdx = (i < pcm.length) ? i : (pcm.length - 1).clamp(0, pcm.length - 1);
      out[i] = (pcm[srcIdx] / 32768.0);
    }
    try { await file.delete(); } catch (_) {}
    return out;
  }

  Future<void> _runInference() async {
    if (inputPath == null || !File(inputPath!).existsSync()) {
      setState(() => status = 'Record something first.');
      return;
    }
    try {
      setState(() => status = 'Loading model…');
      tfl.Interpreter? interpreter;
      try {
        interpreter = await tfl.Interpreter.fromAsset('ml/model.tflite');
      } catch (_) {
        // Graceful fallback if model missing
        setState(() => status = 'Model not found. Using placeholder result.');
        setState(() { output = [1.0]; });
        return;
      }

      final input = await _prepareMonoLogMel(inputPath!);
      // Assuming a simple input shape [1, 16000] and output [1, N]
      final inputTensor = input.reshape([1, 16000]);
      final outLen = labels.length;
      final outTensor = List.filled(outLen, 0.0).reshape([1, outLen]);

      setState(() => status = 'Running inference…');
      interpreter.run(inputTensor, outTensor);
      final probs = List<double>.from(outTensor[0]);
      setState(() {
        output = probs;
        status = 'Done';
      });
      interpreter.close();
    } catch (e) {
      setState(() => status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String topLabel = 'Unknown';
    double topProb = 1.0;
    if (output.isNotEmpty && labels.isNotEmpty) {
      int idx = 0;
      double maxv = -1.0;
      for (int i = 0; i < output.length && i < labels.length; i++) {
        if (output[i] > maxv) { maxv = output[i]; idx = i; }
      }
      topLabel = labels[idx];
      topProb = (maxv < 0) ? 0.0 : maxv;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Classify Signal (ML)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status: $status'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _runInference,
              child: const Text('Run Classification'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Result', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Top label: $topLabel'),
                    if (output.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('All probabilities:'),
                      for (int i = 0; i < output.length && i < labels.length; i++)
                        Text('${labels[i]}: ${output[i].toStringAsFixed(3)}'),
                    ] else
                      const Text('No output yet.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Note: If the bundled model is missing, a placeholder result is shown. '
              'To enable real classification, add a TensorFlow Lite model at assets/ml/model.tflite '
              'and ensure labels.txt matches the output classes.',
            ),
          ],
        ),
      ),
    );
  }
}
