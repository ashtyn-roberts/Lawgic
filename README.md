# lawgic

Lawgic — Civic Engagement Mobile App

Participants:
- Ashtyn Roberts
- Lillian Andino
- D'marrick Guillory
- Cole Latiolais
- Logan Wachter

Lawgic is a Flutter-based mobile application designed to help citizens understand ballot propositions, stay informed on upcoming elections, read simplified summaries of legislation, and interact with their community through comments and notes.
It also includes an integrated AI Assistant powered by Google Gemini to answer civic questions.

Features:

-- Ballot Proposition Explorer
View detailed information on propositions (title, parish, election date, full text)

* Add or remove propositions from Favorites
* Browse your previously saved propositions

-- Comments & Discussions
* Users can leave comments on propositions
* Like / dislike system on each comment
* Real-time updates via Firestore

-- Personal Notes
* Save your own private notes for each proposition
* Easy editing and deleting

-- Favorites System
* Store favorite propositions using Firebase
* Instant sync across devices

-- Map & Calendar Integration
* A map tab for election locations (future expansion)
* A calendar tab for upcoming elections and events

-- AI Assistant
* Uses Google Gemini API to answer user questions
* Custom chat UI with message bubbles
* Error handling for API limits, invalid keys, and timeouts

-- Full Dark Mode Support
* Every screen adapts to system theme
* Custom colors for cards, text, buttons, and background

-- Tech Stack
* Frontend: 
    - Flutter (Dart)
    - Custom dark mode handling
* Backend
    - Firebase Authentication
    - Firebase Firestore
    - Firebase Storage
    - LegiScan API (gets information for legislation in all 50 states and Congress)
    - Gemini Flash 2.5 API
    - Secure API access with locally stored api_keys.dart

-- API Keys & Credentials
* This project uses a file called api_keys.dart to safely store keys. This file is in the project's gitignore. It is IGNORED (!) and each member must generate their own API keys.

▶️ Running the App
-- Clone the repo:
% git clone https://github.com/yourname/lawgic.git
% cd lawgic

-- Install dependencies:
% flutter pub get

-- Create API Keys file
* Copy the example:
% cp lib/config/api_keys_example.dart lib/config/api_keys.dart
* Then fill in your personal keys

-- Run the app:
% flutter run
