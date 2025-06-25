#!/bin/bash

# KISS Firebase Repository - Run Integration Tests
# Requires Android emulator and Firebase emulator to be running

cd "$(dirname "$0")/.."

echo "🧪 Running KISS Firebase Repository Integration Tests"
echo "===================================================="

# Check if we're in the right directory
if [[ ! -f "pubspec.yaml" ]]; then
    echo "❌ Please run this script from the kiss_firebase_repository directory"
    exit 1
fi

# Check if adb is available
if ! command -v adb &> /dev/null; then
    echo "❌ adb command not found!"
    echo "🔧 Please ensure Android SDK is installed and adb is in your PATH"
    exit 1
fi

# Check if Android emulator is running
echo "🔍 Checking if Android emulator is running..."
DEVICES=$(adb devices | grep -E "device$|emulator" | wc -l)
if [ "$DEVICES" -eq 0 ]; then
    echo "❌ No Android emulator or device detected!"
    echo "🚀 Start an Android emulator first or connect a physical device"
    echo "   You can start an emulator from Android Studio or use: emulator @avd_name"
    exit 1
fi

echo "✅ Android emulator/device is available"

# Check if Firebase emulator is running
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

# Run integration tests
echo "🧪 Running integration tests..."
echo "📝 Test results:"
echo ""

flutter test integration_test/all_integration_tests.dart
TEST_EXIT_CODE=$?

echo ""
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ All integration tests passed!"
else
    echo "❌ Some integration tests failed (exit code: $TEST_EXIT_CODE)"
fi

exit $TEST_EXIT_CODE 
