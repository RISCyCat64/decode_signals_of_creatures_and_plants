
import 'package:flutter/material.dart';

class SpectrogramScreen extends StatelessWidget {
  static const routeName = '/spectrogram';

  const SpectrogramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? path = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Spectrogram (Preview)')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Spectrogram Placeholder',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'In the next iteration, this screen will render a real-time or offline spectrogram\n'
                'computed from your last recording using an FFT.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (path != null)
                Text(
                  'Last file:\n$path',
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
