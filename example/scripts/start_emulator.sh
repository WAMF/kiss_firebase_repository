#!/bin/bash

# KISS Firebase Repository - Start Firebase Emulator
# Simple script to start the Firebase Firestore emulator

echo "🔥 Starting Firebase Emulator"
echo "=============================="

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found!"
    echo "📦 Install with: npm install -g firebase-tools"
    exit 1
fi

echo "✅ Firebase CLI found"

# Navigate to root directory (where firebase.json is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT/.."

# Check if firebase.json exists
if [[ ! -f "firebase.json" ]]; then
    echo "❌ firebase.json not found! Make sure you're in the correct project."
    exit 1
fi

echo "🚀 Starting Firestore emulator..."
echo "📍 Emulator will run at: http://localhost:8080"
echo "🌐 Emulator UI will be at: http://localhost:4000"
echo "🛑 Press Ctrl+C to stop the emulator"
echo ""

# Start the emulator (this will block until stopped)
firebase emulators:start --only firestore
