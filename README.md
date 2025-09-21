
# Creatures Decoder — v2
**Repo:** `Decode-Signals-of-Creatures-and-Plants`  
**App name:** *Creatures Decoder*

This is **Version 2**: adds a **real FFT spectrogram** (offline) and an **ML classifier scaffold** using TensorFlow Lite.

## ✅ What’s new in v2
- **Spectrogram:** decodes your recording to mono 16 kHz WAV via FFmpeg, computes FFT frames in Dart, and renders a grayscale heatmap.
- **ML scaffold:** screen to run inference via `tflite_flutter`. If no model is present, it **fails gracefully** with a placeholder result.

## 🔧 Dependencies
- `ffmpeg_kit_flutter_min_gpl` — for decoding AAC → WAV.
- `tflite_flutter` — TensorFlow Lite interpreter (no model bundled by default).
- `flutter_sound`, `permission_handler`, `path_provider` — from v1.

## 📂 Structure
```
lib/
 ├─ main.dart
 ├─ screens/
 │   ├─ home.dart            # Record/playback UI
 │   ├─ spectrogram.dart     # Real FFT spectrogram
 │   └─ classify.dart        # ML inference (graceful if model missing)
assets/
 └─ labels.txt               # Example labels (edit to match your model)
```
> Place your TFLite model at `assets/ml/model.tflite` and update `pubspec.yaml` if you add the assets folder. In this starter, we only include `labels.txt` so the app builds without a model.

## 🏃 Run
```bash
flutter pub get
flutter create .    # if android/ios folders missing
flutter run
```
On iOS, add this to `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app records audio to analyze animal/plant signals.</string>
```

## 🧠 Training & Models (next steps)
- Start with a small model that accepts 1-second mono audio @16 kHz (shape `[1,16000]`) and outputs class probabilities.
- Save as TFLite (`.tflite`) and include as `assets/ml/model.tflite`.
- Ensure `assets/labels.txt` has matching class order.

## ⚠️ Notes
- Spectrogram rendering is grayscale for simplicity. We can add better colormaps and axes later.
- The classifier will show a placeholder if the model is missing, so the UI flow remains testable.
- Plant ultrasonics need > 20 kHz capture; most phone mics won’t reach that. External ultrasonic mics are required.
