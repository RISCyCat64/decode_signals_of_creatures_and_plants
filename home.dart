
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'spectrogram.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecorderReady = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _lastFilePath;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _player.openPlayer();
    await _recorder.openRecorder();

    // Request permissions
    final micStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();

    if (micStatus.isGranted && storageStatus.isGranted) {
      setState(() {
        _isRecorderReady = true;
      });
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone/Storage permission required')),
      );
    }
  }

  Future<String> _nextFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final path = '${dir.path}/creature_${stamp}.aac';
    return path;
  }

  Future<void> _toggleRecord() async {
    if (!_isRecorderReady) return;
    if (_isRecording) {
      final path = await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
        _lastFilePath = path;
      });
    } else {
      final path = await _nextFilePath();
      await _recorder.startRecorder(toFile: path, codec: Codec.aacADTS);
      setState(() {
        _isRecording = true;
        _lastFilePath = path;
      });
    }
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.stopPlayer();
      setState(() => _isPlaying = false);
      return;
    }
    if (_lastFilePath == null || !File(_lastFilePath!).existsSync()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record something first')),
      );
      return;
    }
    await _player.startPlayer(
      fromURI: _lastFilePath,
      codec: Codec.aacADTS,
      whenFinished: () => setState(() => _isPlaying = false),
    );
    setState(() => _isPlaying = true);
  }

  @override
  void dispose() {
    _player.closePlayer();
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creatures Decoder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Record & Playback',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isRecording ? 'Recording…' : 'Ready',
                      style: TextStyle(
                        color: _isRecording ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _toggleRecord,
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          label: Text(_isRecording ? 'Stop' : 'Record'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _togglePlay,
                          icon: Icon(_isPlaying ? Icons.stop_circle : Icons.play_arrow),
                          label: Text(_isPlaying ? 'Stop' : 'Play'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_lastFilePath != null)
                      Text(
                        'Saved: ${_lastFilePath}',
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  SpectrogramScreen.routeName,
                  arguments: _lastFilePath,
                );
              },
              child: const Text('Open Spectrogram'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tip: For best results, record close to the sound source and avoid wind/traffic. '
              'This MVP saves audio locally; spectrogram is a placeholder to be replaced with real FFT soon.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
