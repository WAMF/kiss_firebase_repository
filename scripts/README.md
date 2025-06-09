# Scripts

This directory contains helper scripts for the KISS Firebase Repository example.

## 🔥 `start_emulator.sh`
**Purpose**: Start the Firebase emulator  
**Usage**: `./start_emulator.sh`  
**Description**: Starts the Firestore emulator and keeps it running.

## 📱 `run_app.sh`
**Purpose**: Run the Flutter app  
**Usage**: `./run_app.sh`  
**Description**: Checks if the emulator is running, installs dependencies, and starts the Flutter app.

## 🧪 `run_tests.sh`
**Purpose**: Run integration tests  
**Usage**: `./run_tests.sh`  
**Description**: Checks if the emulator is running, installs dependencies, and runs the integration tests.

## Typical Workflow

1. Terminal 1: `./start_emulator.sh` (keep running)
2. Terminal 2: `./run_app.sh` (for development)
3. Terminal 3: `./run_tests.sh` (when needed)

## Manual Control

If you prefer, you can:
1. Start the emulator: `./start_emulator.sh`
2. Use Flutter tools directly: `flutter run`, `flutter test`, etc. 
