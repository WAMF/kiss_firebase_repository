#!/bin/bash

# KISS Firebase Repository Example - Run Integration Tests
# Simple script to run integration tests (assumes emulator is already running)

echo "🧪 Running KISS Firebase Repository Integration Tests"
echo "===================================================="

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

# Run integration tests
echo "🧪 Running integration tests..."
echo "📝 Test results:"
echo ""

flutter test integration_test/app_test.dart
TEST_EXIT_CODE=$?

echo ""
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ All integration tests passed!"
else
    echo "❌ Some integration tests failed (exit code: $TEST_EXIT_CODE)"
fi

exit $TEST_EXIT_CODE 
