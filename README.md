
# Creatures Decoder
**Repo:** `Decode-Signals-of-Creatures-and-Plants`  
**App name:** *Creatures Decoder*

Record, visualize, and (soon) decode acoustic signals from animals and plants.

## ✨ MVP Features (Phase 1)
- Record audio (AAC) and save locally
- Playback the last recording
- Navigate to a **Spectrogram** screen (placeholder; FFT coming next)

## 🔮 Roadmap
**Phase 2 – Spectrogram & Analysis**
- Compute and render spectrograms (offline) using FFT
- Markers & labels for call types

**Phase 3 – AI Decoding**
- TensorFlow Lite model for cat meows / dog barks / bird calls
- Personalized training with your own labeled data

**Phase 4 – Plants & Community**
- Ultrasonic stress-clicks in plants (requires >48 kHz mics)
- Optional cloud dataset (Firebase) and model updates

## 📱 Run Locally
1. Install Flutter (stable channel).
2. Clone this repo, then inside the project folder run:
   ```bash
   flutter pub get
   # If platform folders are missing, generate them:
   flutter create .
   flutter run
   ```

## ⚙️ Permissions
- Microphone is required to record.
- On Android, ensure `RECORD_AUDIO` is present (Flutter will inject via plugins).
- On iOS, add these to `ios/Runner/Info.plist` after `flutter create .`:
  ```xml
  <key>NSMicrophoneUsageDescription</key>
  <string>This app records audio to analyze animal/plant signals.</string>
  ```

## 🧩 Tech Stack
- Flutter + Dart
- Packages: `flutter_sound`, `permission_handler`, `path_provider`

## 📝 Notes
- Files are stored in the app documents directory with timestamped names.
- Spectrogram is a placeholder; the next commit will add real FFT-based rendering.

## 📄 License
MIT
