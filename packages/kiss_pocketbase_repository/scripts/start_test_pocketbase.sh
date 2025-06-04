#!/bin/bash

# Start PocketBase with test data directory for integration tests

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DATA_DIR="$SCRIPT_DIR/../test_pb_data"

echo "🚀 Starting PocketBase test server..."
echo "📁 Using test data directory: $TEST_DATA_DIR"

# Check if pocketbase is installed
if ! command -v pocketbase &> /dev/null; then
    echo "❌ PocketBase not found. Please install it first:"
    echo "   brew install pocketbase"
    echo "   or download from https://pocketbase.io/docs/"
    exit 1
fi

# Create test data directory if it doesn't exist
mkdir -p "$TEST_DATA_DIR"

echo "✅ Starting PocketBase on http://localhost:8090"
echo "📊 Admin UI: http://localhost:8090/_/"
echo "🔧 Test admin: test@test.com / testpassword123"
echo ""
echo "Press Ctrl+C to stop the server"

# Start PocketBase with test data directory
pocketbase serve --dir="$TEST_DATA_DIR" --http="localhost:8090" 