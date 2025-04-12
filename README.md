# SeniorProject
CMSI 4071

## Overview

Momento is a mobile visual journaling app that enables users to record and reflect on daily life through mood check-ins, photo journaling, and motivational quotes—without needing to write. This app was developed as part of the CMSI 4071/4072 course sequence at Loyola Marymount University. It integrates Firebase for secure data storage, SwiftUI for the iOS interface, and includes custom features like a Daily Quote Generator and Monthly Recap builder.

## Purpose

The app aims to simplify daily journaling by removing the pressure of writing. Users can log their mood, snap a photo, optionally add a note, and revisit their month in a visual summary. Momento supports emotional wellness, mindfulness, and self-reflection in a lightweight, intuitive way.

## Features

📸 Photo Journaling: Capture and save a daily photo with optional vintage filters
😌 Mood Check-ins: Select from multiple mood icons each day
📝 Optional Notes: Add a brief note to each journal entry
🧠 Daily Quotes: Receive a fresh motivational quote each day
📆 Monthly Recaps: Visual summaries of the month’s entries and mood trends
🔐 User Authentication: Sign in securely with Firebase Authentication
☁️ Persistent Storage: All entries stored in Firebase Firestore

## Subsystems

Authentication — Handles login, logout, and session state
Journal Entry — Captures photos, moods, and notes
Quote Manager — Fetches and displays daily motivational quotes
Monthly Recap — Aggregates data into a visual summary
Database Services — Interfaces with Firebase for secure data operations

## Technologies Used

SwiftUI (Frontend)
Firebase Firestore (Database)
Firebase Authentication (User Login)
Xcode 15+ (Development Environment)
XCTest (Unit & Integration Testing)

## Installation & Setup

Clone the repository from GitHub
Open the project in Xcode
Make sure to install all Firebase dependencies via Swift Package Manager
Add your own GoogleService-Info.plist to enable Firebase
Build and run on a simulator or physical iOS device

## Usage Instructions

Launch the app and sign in
Tap the camera icon to take and save your daily photo
Tap the smiley face to check in with your mood
Navigate to past entries through the archive
Tap the quote icon to read a daily motivational message
Tap the calendar icon to view your monthly recap

## Performance

App launch time: < 2 seconds (approx)
Quote fetch time: < 1 second (cached if offline)
Firebase sync latency: < 3 seconds for typical Wi-Fi
Entry save and load verified under both emulator and real device conditions

## Known Issues / Limitations

Gesture-based UI interactions (e.g., long press) not yet fully testable
Quote API fallback not implemented for offline mode
Only one image per day is supported for now

## Testing

The app has been rigorously tested via:
Manual Functional Testing: Verifying each user-facing feature
Unit Tests: For QuoteManager, JournalEntryViewModel, etc.
Integration Tests: Covering full journal entry creation and recap generation
Testing procedures are detailed in the Test Procedure Document.

## Requirements Summary (Agile Format)

As a user, I want to save a photo daily so that I can track memories visually
As a user, I want to record my mood each day so that I can reflect on my emotions
As a user, I want to see a motivational quote every day to start with inspiration
As a user, I want to see a visual recap of my month so I can recognize patterns
As a user, I want my data to be securely stored and synced across devices

## Environment Requirements

iOS 17 or higher
Swift 5.9+
Firebase project setup with Authentication and Firestore enabled

## Contributors

Ria Singh, Anika Bhatnagar

## License

This project is for academic use under Loyola Marymount University's CMSI 4072 course.

## Week 7 Status Report
This week, we worked on revisiting and refining the scope of our project based on the feedback received. We started drafting new functional requirements in Agile format to better reflect the updated feature set. We also discussed and mapped out responsibilities across the five main subsystems, and began sketching updates to our UI wireframes in Xcode.

## Week 9 Status Report
We continued working on the development of new features, with a focus on the Daily Quote Generator. Efforts went into structuring how quotes will be fetched and displayed on the home screen. We also began updating our data models and Firebase structure to accommodate quote storage. Some initial testing setup was explored using XCTest.

## Week 11 Status Report
This week, we worked on building out the Monthly Recap view and discussed how to organize journaled moods and photos visually. We also spent time debugging an issue related to photo retrieval from Firebase and explored caching solutions. Unit tests for the Quote and Recap features were outlined, and we began testing the interaction flow between components.

## Week 13 Status Report
We focused on documentation this week, including updating the Test Procedure Document and revising the README to reflect this semester’s development goals. We also reviewed the professor’s feedback on the SRS and started reworking our requirements to meet those expectations. Design and testing work continued across the core features, including the journal entry system, quote logic, and monthly recap layout.


