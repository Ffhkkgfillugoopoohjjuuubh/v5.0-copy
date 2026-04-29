# Echo AI v3.0

Echo AI is a Flutter teaching assistant app powered by Groq, ML Kit OCR,
Flutter TTS, AdMob banners, local chat storage, projects, news feeds, and
multi-language voice playback.

## Run

```powershell
flutter pub get
flutter run --dart-define=GROQ_API_KEY=your_groq_key_here
```

The API key is intentionally read with `String.fromEnvironment` so it does not
need to be committed to the repository.
