# claRity (Internal: DislexIA)

**claRity** is a 100% on-device, native iOS accessibility application designed to assist users with dyslexia. 

## 🧠 Architecture & Engineering

### 100% On-Device Processing
To ensure maximum privacy and offline capability, claRity operates entirely on-device without any backend or third-party SDK dependencies (excluding the OpenDyslexic font).

### Core Engines
- **Spanish Syllabifier Algorithm**: A custom, highly optimized algorithm designed to accurately parse and tokenize Spanish text into correct syllables.
- **Vision OCR Module**: Integrates Apple's `Vision` framework to perform on-device Optical Character Recognition (OCR), extracting text directly from the camera feed or photo library.
- **TTS + Syllable Sync Engine**: Wraps `AVSpeechSynthesizer` to provide synchronized text-to-speech, highlighting syllables in real-time as they are spoken.
- **FoundationModels (iOS 18)**: Leverages Apple's latest on-device Foundation Models for AI-driven reading comprehension questions and dynamic text simplification.

### UI & Persistence
- **SwiftUI**: The entire interface is built declaratively with SwiftUI for iOS 18+.
- **SwiftData**: Manages the persistence layer for the `LibraryStore`, saving reading sessions, user preferences, and comprehension scores.