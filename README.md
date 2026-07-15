# GemScan – AI-Powered Offline Medication Safety Assistant

**GemScan** is an on-device AI healthcare assistant that helps users understand medicine safety by combining **Google ML Kit OCR**, **Gemma-4-E2B-it-LiteRT-LM**, and patient medical history to provide personalized medication guidance—all without requiring an internet connection.

The application scans medicine packages using the device camera, extracts text through on-device OCR, recognizes medicines, and analyzes them alongside the patient's health profile (age, diseases, allergies, pregnancy status, sleep cycle, and lifestyle) to generate easy-to-understand medical advice.

## ✨ Features

- 📷 Camera-based medicine scanning
- 🔍 Google ML Kit OCR for text extraction
- 💊 Medicine recognition from scanned labels
- 👤 Personalized patient profiles

- Age
- Existing diseases
- Allergies
- Pregnancy status
- Regular medications
- Sleep schedule
- Lifestyle information
- 🤖 On-device AI inference using **Gemma-4-E2B-it-LiteRT-LM**
- 🧠 Explainable AI Reasoning Flow
- 🍽 Food interaction & medication timing recommendations
- ⚠ Drug–drug interaction detection
- ❤️ Patient-friendly, easy-to-understand explanations
- 🔒 100% offline processing (no patient data leaves the device)
- 📱 Flutter cross-platform application

---

## 🛠 Tech Stack

- Flutter
- Dart
- Google ML Kit OCR
- Gemma-4-E2B-it-LiteRT-LM
- LiteRT (TensorFlow Lite Runtime)
- Android Camera API
- JSON Local Storage

---

## AI Workflow

```
Medicine Strip
        │
        ▼
Camera Scan
        │
        ▼
Google ML Kit OCR
        │
        ▼
Medicine Recognition
        │
        ▼
Patient Profile
(Age • Diseases • Allergies • Pregnancy • Sleep Cycle • Lifestyle)
        │
        ▼
Gemma-4-E2B-it-LiteRT-LM
(On-device)
        │
        ▼
Personalized Analysis
        │
        ▼
Easy-to-understand Advice
```

---

## Key Highlights

- Fully offline AI inference
- Privacy-first architecture
- Personalized healthcare recommendations
- Explainable AI reasoning visualization
- Optimized for Android devices
- Built for healthcare accessibility

---

## Project Structure

```
lib/
 ├── models/
 ├── screens/
 ├── services/
 ├── utils/
 ├── widgets/
 └── theme/
```

---

## Demo

📺 Demo Video:

https://youtu.be/cq3739W5RkI?si=OXA3LURSsZhz0Wev

---

## Future Improvements

- Medicine reminder system
- Voice assistant support
- Multi-language support
- Expanded drug knowledge base
- Barcode-based medicine identification
- Doctor & pharmacist integration

---

## Disclaimer

GemScan is an educational and research project developed for an AI Hackathon. It is designed to assist users by providing medication information and should not replace professional medical advice, diagnosis, or treatment.

---

## License

MIT License

---

### Suggested GitHub Topics

When creating the repository, add these topics:

```
flutter
dart
gemma
gemma-4
google-ml-kit
ocr
medical-ai
healthcare
on-device-ai
tensorflow-lite
litert
android
medicine
drug-interaction
offline-ai
hackathon
explainable-ai
patient-safety
ai-healthcare
```
