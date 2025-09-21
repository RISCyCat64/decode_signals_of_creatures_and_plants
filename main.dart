
import 'package:flutter/material.dart';
import 'screens/home.dart';
import 'screens/spectrogram.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CreaturesDecoderApp());
}

class CreaturesDecoderApp extends StatelessWidget {
  const CreaturesDecoderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Creatures Decoder',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const HomeScreen(),
      routes: {
        SpectrogramScreen.routeName: (_) => const SpectrogramScreen(),
      },
    );
  }
}
