# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Echo is an iOS language learning application built with SwiftUI and SwiftData. The app features three main sections accessible via TabView navigation: Daily Wave (daily practice), Echo Challenge (voice recording challenges), and Profile (learning progress and settings). Users can log in with a nickname and track their vocabulary learning journey.

## Build Commands

### iOS Application
```bash
# Build the iOS app for simulator
xcodebuild -scheme Echo -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Build for specific iOS simulator (check available devices with `xcrun simctl list devices`)
xcodebuild -scheme Echo -destination 'platform=iOS Simulator,name=iPhone 16' build

# Clean build
xcodebuild -scheme Echo clean
```

### Testing
```bash
# Run unit tests
xcodebuild -scheme Echo -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Run UI tests
xcodebuild -scheme Echo -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:EchoUITests

# Run specific test class
xcodebuild test -scheme Echo -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:EchoTests/WordItemTests
```

## Architecture Overview

### Core Data Layer
- **SwiftData** is used for local data persistence
- **Main Models**: `WordItem`, `VocabularySet`, `LearningSession`
- **Schema**: Defines relationships between words, vocabulary collections, and learning sessions
- Data is persisted locally, not in memory only

### Navigation Structure
- **LoginView**: Entry point with nickname authentication
- **MainTabView**: Primary navigation container with three tabs
- **Tab Views**: DailyWaveView, EchoChallengeView, ProfileView
- **Modal Views**: SettingsView, WordDetailView (for detailed word information)

### Key Components

#### Login System
- LoginView handles user authentication with nickname input
- Uses UserDefaults for simple session persistence
- Transitions to MainTabView upon successful login

#### Learning Features
- **Daily Wave**: Daily language practice with inspirational content
- **Echo Challenge**: Voice recording and playback comparison features
- **Profile**: Learning streak calendar, practice history, user statistics

#### Data Models
- **WordItem**: Individual vocabulary entries with difficulty levels and learning progress
- **VocabularySet**: Collections of related words
- **LearningSession**: Tracks practice sessions and performance metrics

### UI Architecture
- SwiftUI-based with MVVM pattern
- Consistent dark theme across all pages
- Custom color scheme: Primary blue (#5b6fd8), background (#1a1d2e)
- Responsive design using SwiftUILayoutGuide and safe area handling

### Settings and Configuration
- SettingsView provides API configuration (address, key, model name)
- Configuration persisted using UserDefaults
- Input validation and error handling for API settings

## Design System
- **Color Palette**: Dark backgrounds (#1a1d2e, #1a1f2e) with blue accents (#5b6fd8, #6b7bea)
- **Typography**: System fonts with custom tracking and weights
- **Components**: Reusable card designs, input fields, buttons with consistent styling
- **Layout**: VStack/HStack with proper spacing, responsive padding, and safe area handling

## Development Notes

- The app uses Figma MCP server for design assets and UI generation
- All views follow the established dark theme pattern
- Navigation is handled centrally through MainTabView to avoid duplicated navigation elements
- SwiftData model container is configured at app level and shared across all views
- Error handling uses alert presentations for user feedback

## Database Schema

The app uses SQLite database with the following structure:

### Static Knowledge Base (App-level Data)
These tables are pre-populated with initial data and rarely change during app lifecycle.

#### Words Table
Stores core learning content including words, definitions, example sentences, and substitutes.
```sql
CREATE TABLE Words (
    wordId INTEGER PRIMARY KEY AUTOINCREMENT,  -- Unique word identifier
    wordString TEXT NOT NULL UNIQUE,           -- Word in lowercase
    phonetic TEXT,                             -- IPA phonetic transcription (nullable)
    partsOfSpeech TEXT,                        -- JSON string with definitions (nullable)
    dailySentence TEXT,                        -- JSON string with example sentences (nullable)
    dailySubstitutes TEXT,                     -- JSON string with common substitutes (nullable)
    usageAnalysis TEXT                         -- Example sentence usage analysis (nullable)
);
```

#### Pronunciations Table
Independent pronunciation dictionary containing ARPAbet transcriptions from cmudict.
```sql
CREATE TABLE Pronunciations (
    word TEXT PRIMARY KEY,                     -- Word in uppercase
    arpabet TEXT NOT NULL                      -- ARPAbet phonetic transcription
);
```

### Dynamic User Data (User-level Data)
These tables are created empty and populated dynamically during user interaction.

#### Users Table
Stores basic user information (typically one record in single-user app).
```sql
CREATE TABLE Users (
    userId INTEGER PRIMARY KEY,                -- Unique user identifier (defaults to 1)
    createdAt TEXT,                            -- Account creation time (ISO 8601 format)
    lastLoginAt TEXT                           -- Last login time (ISO 8601 format)
);
```

#### LearningPlans Table
Manages user learning plans and progress queues for flexible goal setting.
```sql
CREATE TABLE LearningPlans (
    userId INTEGER PRIMARY KEY,                -- User ID (references Users table)
    defaultDailyGoal INTEGER,                  -- Default daily new word goal
    learningQueue TEXT,                        -- JSON string with ordered wordId array
    dailyGoalOverrides TEXT                    -- JSON string with {"YYYY-MM-DD": goal} dictionary
);
```

#### UserWordData Table
Records learning status for each word, forming the foundation of the intelligent review system (spaced repetition).
```sql
CREATE TABLE UserWordData (
    userId INTEGER,                            -- User ID
    wordId INTEGER,                            -- Word ID (references Words table)
    masteryLevel INTEGER,                      -- Mastery level (1=new, 5=mastered)
    nextReviewAt TEXT,                         -- Next review time (ISO 8601 format)
    lastReviewedAt TEXT,                       -- Last review time (ISO 8601 format)
    incorrectCount INTEGER,                    -- Total incorrect attempts
    isLearned INTEGER,                         -- Learning status (boolean 0/1)
    PRIMARY KEY (userId, wordId)               -- Composite key ensures unique record per user-word pair
);
```

#### UserStats Table
Stores user statistics and motivation system information like streaks and scores.
```sql
CREATE TABLE UserStats (
    userId INTEGER PRIMARY KEY,                -- User ID
    currentStreak INTEGER,                     -- Current consecutive check-in days
    longestStreak INTEGER,                     -- Historical longest streak
    lastCheckinDate TEXT,                      -- Last check-in date (YYYY-MM-DD format)
    totalScore INTEGER,                        -- Total user score/experience points
    totalWordsLearned INTEGER                  -- Total learned words count
);
```

### Data Models Mapping
Swift models in `/Echo/Models/DatabaseModels.swift`:
- `Word` ↔ Words table (includes usageAnalysis field for example sentence analysis)
- `Pronunciation` ↔ Pronunciations table
- `User` ↔ Users table
- `LearningPlan` ↔ LearningPlans table
- `UserWordData` ↔ UserWordData table
- `UserStats` ↔ UserStats table

**Recent Update**: Added `usageAnalysis` field to Words table and Word model to store detailed analysis of word usage, grammar roles, and context from example sentences. This field corresponds to the `roleAnalysis` field from offline_data.json.

### Database Service
- **Location**: `/Echo/Services/DatabaseService.swift`
- **Auto-initialization**: Creates database with sample data on first launch
- **Singleton Pattern**: `DatabaseService.shared` for app-wide access
- **Operations**: Word queries, random selection, user management, sentence extraction

## File Organization
- `/Echo/Models/`: SwiftData model definitions and Database models
- `/Echo/Views/`: SwiftUI view components and screens
- `/Echo/Services/`: Database and business logic services
- `/Echo/EchoApp.swift`: App entry point and configuration
- `/Echo/Assets.xcassets`: Image assets and design resources
- `/Echo/InitData/`: Original database files and initialization data