#!/bin/bash

# KISS Firebase Repository Example - Run App
# Simple script to run the Flutter app (assumes emulator is already running)

echo "📱 Starting KISS Firebase Repository Example App"
echo "================================================"

# Check if we're in the right directory
if [[ ! -f "pubspec.yaml" ]]; then
    echo "❌ Please run this script from the example directory"
    exit 1
fi

# Check if emulator is running
echo "🔍 Checking if Firebase emulator is running..."
if ! curl -s http://localhost:8080 > /dev/null; then
    echo "❌ Firebase emulator not running!"
    echo "🚀 Start it first with: ./scripts/start_emulator.sh"
    echo "   (or run it in another terminal)"
    exit 1
fi

echo "✅ Firebase emulator is running"

# Install dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Run the app
echo "🚀 Starting Flutter app..."
echo "📱 App will connect to Firebase emulator at localhost:8080"
echo "🌐 Monitor data at: http://localhost:4000"
echo ""

flutter run 
