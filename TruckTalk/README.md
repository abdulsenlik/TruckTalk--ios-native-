# TruckTalk - Mobile English Learning for Truck Drivers

A native iOS app built with Swift and SwiftUI designed specifically for truck drivers learning English. The app provides audio-driven lessons, emergency phrase practice, and structured module progression optimized for mobile learning.

## 🚛 Overview

TruckTalk is a mobile-first English learning tool that faithfully recreates and enhances the structure and educational utility of the web platform, specifically optimized for iPhone use by truck drivers and ESL learners.

### Key Features

- **5-Day Bootcamp System**: Structured daily lessons covering essential trucking vocabulary
- **Emergency Phrases**: Quick-access categorized phrases for emergency situations
- **Audio-First Learning**: All content includes pronunciation audio using AVFoundation
- **Offline-Ready**: Bundled audio files for learning without internet connectivity
- **Progress Tracking**: User progress, streaks, and achievement system
- **Dark Mode Support**: Full dark mode with comfortable low-light design
- **Accessibility**: VoiceOver support and Dynamic Type compatibility

## 🏗️ Architecture

### Tech Stack
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Audio**: AVFoundation
- **State Management**: ObservableObject, Combine
- **Data Layer**: Mock JSON (future-ready for Firebase/Supabase)

### Project Structure

```
TruckTalk/
├── Models/
│   └── LessonModels.swift          # Core data models
├── Services/
│   ├── AudioManager.swift          # Audio playback management
│   └── DataService.swift           # Data management and mock content
├── Views/
│   ├── HomeView.swift              # Main dashboard with bootcamp days
│   ├── LessonDetailView.swift      # Detailed lesson with expandable sections
│   ├── EmergencyPhrasesView.swift  # Emergency phrases by category
│   └── MainTabView.swift           # Tab navigation container
├── Components/
│   ├── LessonCard.swift            # Reusable lesson card with progress
│   └── AudioCard.swift             # Audio phrase card component
├── Extensions/
│   └── ColorExtensions.swift       # Theme and color system
└── Assets.xcassets/                # App icons and colors
```

## 🎨 Design System

### Visual Design
- **Clean, ergonomic interface** optimized for one-handed use
- **Thumb-friendly interaction design** for large iPhone screens
- **Calming, trustworthy aesthetic** with soft shadows and muted accents
- **Strong visual hierarchy** with generous padding and clear typography

### Dark Mode
- **Full dark mode support** using dynamic color tokens
- **Soft shadows and deep grays** instead of pure black
- **High-contrast but muted accent colors** to reduce eye strain

### Accessibility
- **Minimum 44x44pt tap targets** for reliable touch interaction
- **Dynamic Type support** for scalable text
- **VoiceOver compatibility** with descriptive labels
- **Clear visual feedback** for all interactive elements

## 📱 Core Components

### LessonCard
- Displays day title, description, and completion percentage
- Progress ring animation with lock/unlock status
- Accessibility labels for VoiceOver support

### AudioCard
- English phrase with optional translation
- Audio playback controls with AVAudioPlayer
- Favorite and completion status management
- Consistent visual styling across app

### Emergency Categories
- Police Stop, Vehicle Trouble, Medical Emergency
- Road Assistance, Communication
- Color-coded for quick visual identification
- Priority-based phrase ordering

## 🔊 Audio System

### AVFoundation Integration
- **Offline audio playback** with bundled MP3 files
- **Background-compatible audio session** for truck cab use
- **Progress tracking** with visual playback indicators
- **Automatic session management** with proper cleanup

### Audio File Structure
```
Bundle.main/
├── vocab_1_0.mp3      # Day 1 vocabulary items
├── dialogue_1_1.mp3   # Day 1 dialogue practice
├── police_license.mp3 # Emergency phrases
└── medical_help.mp3   # Critical situation phrases
```

## 📊 Progress System

### User Progress Tracking
- **Lesson completion status** with persistent storage
- **Daily streak tracking** with motivational indicators
- **Study time accumulation** for progress insights
- **Achievement unlocks** based on milestones

### Bootcamp Progression
- **Sequential day unlocking** based on previous completion
- **Section-based progress** (Vocabulary, Dialogue, Pronunciation)
- **Percentage completion** with visual progress rings
- **Favorited phrases** for quick review access

## 🚀 Getting Started

### Prerequisites
- iOS 16.0+
- Xcode 15.0+
- iPhone (optimized for large screens)

### Installation
1. Clone the repository
2. Open `TruckTalk.xcodeproj` in Xcode
3. Build and run on device or simulator
4. Audio files will be bundled automatically

### Mock Data
The app currently uses mock data for development:
- 5 days of bootcamp content with vocabulary and dialogues
- Emergency phrases across 5 categories
- Simulated user progress and achievements

## 🔮 Future Enhancements

### Backend Integration
- **Firebase/Supabase integration** for real user data
- **Cloud sync** for cross-device progress
- **Real-time analytics** for learning insights
- **User authentication** and profile management

### Enhanced Features
- **Speech recognition** for pronunciation practice
- **Offline content updates** with background sync
- **Personalized learning paths** based on progress
- **Social features** for trucker community engagement

### Content Expansion
- **Regional trucking terminology** variations
- **DOT regulation phrases** for compliance scenarios
- **Route-specific vocabulary** for different regions
- **Advanced conversation practice** with AI

## 👥 Target Audience

**Primary Users**: Truck drivers learning English as a second language
**Use Cases**: 
- Quick learning sessions during mandatory rest periods
- Emergency phrase reference during road incidents
- Progressive skill building over extended trips
- Offline study in areas with poor connectivity

## 🎯 Learning Objectives

1. **Essential Trucking Vocabulary**: Industry-specific terms and phrases
2. **Emergency Communication**: Critical phrases for safety situations
3. **Professional Interactions**: DOT stops, loading/delivery communication
4. **Pronunciation Confidence**: Audio-first approach for speaking skills
5. **Cultural Integration**: Understanding American trucking culture and communication norms

## 📝 License

This project is designed as an educational tool for truck drivers and represents a mobile adaptation of existing web-based English learning resources.

---

**Built with ❤️ for the trucking community**

*Empowering drivers to communicate confidently on America's highways* 