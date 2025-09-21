
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';

class SpectrogramScreen extends StatefulWidget {
  static const routeName = '/spectrogram';

  const SpectrogramScreen({super.key});

  @override
  State<SpectrogramScreen> createState() => _SpectrogramScreenState();
}

class _SpectrogramScreenState extends State<SpectrogramScreen> {
  String? inputPath;
  List<List<double>>? spectrogram; // [time][freqBin] magnitude
  String status = 'Idle';
  int sampleRate = 16000; // Target SR for analysis
  int fftSize = 1024;
  int hopSize = 512;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    inputPath = ModalRoute.of(context)?.settings.arguments as String?;
    if (inputPath != null) {
      _processFile(inputPath!);
    } else {
      setState(() => status = 'No file provided.');
    }
  }

  Future<void> _processFile(String src) async {
    setState(() => status = 'Decoding audio…');
    try {
      final dir = await getApplicationDocumentsDirectory();
      final wavOut = '${dir.path}/tmp_spec_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Decode to mono, 16kHz, 16-bit PCM WAV using ffmpeg
      final cmd = "-y -i \"$src\" -ac 1 -ar $sampleRate -f wav \"$wavOut\"";
      await FFmpegKit.execute(cmd);

      // Read WAV and extract PCM16 samples (skip header 44 bytes)
      final file = File(wavOut);
      if (!await file.exists()) {
        throw Exception('Decoded WAV not found.');
      }
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes <= 44) {
        throw Exception('WAV too short.');
      }
      final pcm = bytes.buffer.asInt16List(44); // little-endian by default
      final samples = Float64List(pcm.length);
      const scale = 1.0 / 32768.0;
      for (var i = 0; i < pcm.length; i++) {
        samples[i] = pcm[i] * scale;
      }

      setState(() => status = 'Computing spectrogram…');
      final spec = _computeSpectrogram(samples, fftSize: fftSize, hopSize: hopSize);
      setState(() {
        spectrogram = spec;
        status = 'Done';
      });

      // Optionally delete temp file
      try { await file.delete(); } catch (_) {}
    } catch (e) {
      setState(() => status = 'Error: $e');
    }
  }

  List<List<double>> _computeSpectrogram(List<double> samples, {int fftSize = 1024, int hopSize = 512}) {
    final window = _hannWindow(fftSize);
    final frames = <List<double>>[];
    for (int start = 0; start + fftSize <= samples.length; start += hopSize) {
      final re = List<double>.filled(fftSize, 0);
      final im = List<double>.filled(fftSize, 0);
      for (int i = 0; i < fftSize; i++) {
        re[i] = samples[start + i] * window[i];
      }
      _fft(re, im); // in-place FFT
      final mags = List<double>.filled(fftSize ~/ 2, 0);
      for (int k = 0; k < mags.length; k++) {
        final m = math.sqrt(re[k]*re[k] + im[k]*im[k]);
        mags[k] = 20 * math.log(1e-12 + m); // log scale
      }
      frames.add(mags);
    }
    return frames;
  }

  List<double> _hannWindow(int n) {
    final w = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      w[i] = 0.5 * (1 - math.cos(2 * math.pi * i / (n - 1)));
    }
    return w;
  }

  // In-place Radix-2 Cooley–Tukey FFT (real/imag arrays)
  void _fft(List<double> re, List<double> im) {
    final n = re.length;
    if ((n & (n - 1)) != 0) {
      throw ArgumentError('FFT size must be power of 2');
    }
    // Bit-reversal permutation
    int j = 0;
    for (int i = 1; i < n - 1; i++) {
      int bit = n >> 1;
      while (j & bit != 0) {
        j ^= bit;
        bit >>= 1;
      }
      j |= bit;
      if (i < j) {
        final tr = re[i]; re[i] = re[j]; re[j] = tr;
        final ti = im[i]; im[i] = im[j]; im[j] = ti;
      }
    }
    // FFT
    for (int len = 2; len <= n; len <<= 1) {
      final ang = -2 * math.pi / len;
      final wlenRe = math.cos(ang);
      final wlenIm = math.sin(ang);
      for (int i = 0; i < n; i += len) {
        double wRe = 1.0, wIm = 0.0;
        for (int j2 = 0; j2 < len/2; j2++) {
          final uRe = re[i + j2];
          final uIm = im[i + j2];
          final vRe = re[i + j2 + len~/2] * wRe - im[i + j2 + len~/2] * wIm;
          final vIm = re[i + j2 + len~/2] * wIm + im[i + j2 + len~/2] * wRe;
          re[i + j2] = uRe + vRe;
          im[i + j2] = uIm + vIm;
          re[i + j2 + len~/2] = uRe - vRe;
          im[i + j2 + len~/2] = uIm - vIm;
          final nwRe = wRe * wlenRe - wIm * wlenIm;
          final nwIm = wRe * wlenIm + wIm * wlenRe;
          wRe = nwRe; wIm = nwIm;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spectrogram')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status: $status'),
            const SizedBox(height: 8),
            if (spectrogram != null)
              Expanded(child: SpectrogramView(spectrogram: spectrogram!, fftSize: fftSize, sampleRate: sampleRate))
            else
              const Expanded(
                child: Center(child: Text('Processing or no data yet…')),
              ),
          ],
        ),
      ),
    );
  }
}

class SpectrogramView extends StatelessWidget {
  final List<List<double>> spectrogram; // [time][freq]
  final int fftSize;
  final int sampleRate;
  const SpectrogramView({super.key, required this.spectrogram, required this.fftSize, required this.sampleRate});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _SpecPainter(spectrogram, fftSize, sampleRate),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

class _SpecPainter extends CustomPainter {
  final List<List<double>> spec;
  final int fftSize;
  final int sampleRate;
  _SpecPainter(this.spec, this.fftSize, this.sampleRate);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cols = spec.length;
    if (cols == 0) return;
    final rows = spec[0].length;
    double colW = size.width / cols;
    double rowH = size.height / rows;

    // Find global min/max to normalize
    double minV = double.infinity, maxV = -double.infinity;
    for (final col in spec) {
      for (final v in col) {
        if (v < minV) minV = v;
        if (v > maxV) maxV = v;
      }
    }
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);

    for (int x = 0; x < cols; x++) {
      final col = spec[x];
      for (int y = 0; y < rows; y++) {
        final norm = (col[y] - minV) / range; // 0..1
        // Simple grayscale colormap (can improve later)
        final c = (norm * 255).clamp(0, 255).toInt();
        paint.color = Color.fromARGB(255, c, c, c);
        canvas.drawRect(Rect.fromLTWH(x * colW, size.height - (y+1) * rowH, colW, rowH), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
