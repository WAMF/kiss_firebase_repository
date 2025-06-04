#!/bin/bash
set -e

# 🔄 Clean previous data and migrations
rm -rf test_pb_data
rm -rf pb_migrations

PB_DIR="test_pb_data"
mkdir -p "$PB_DIR"

echo "🚀 Setting up PocketBase..."

# ✅ Check PocketBase installed
if ! command -v pocketbase &>/dev/null; then
  echo "❌ Install PocketBase: https://pocketbase.io/docs/"
  exit 1
fi

# 🚀 Start PocketBase in background
echo "🔧 Starting PocketBase with $PB_DIR..."
pocketbase serve --dir="$PB_DIR" --http="127.0.0.1:8090" &
PB_PID=$!

# ⏳ Wait for PocketBase to initialize
sleep 3

# 👤 Create superuser (admin for API access)
echo "Creating superuser..."
pocketbase superuser upsert test@test.com testpassword123 --dir="$PB_DIR"

# Wait a bit more for the superuser to be ready
sleep 2

# 🔐 Get admin token for API calls
echo "Getting admin token..."
ADMIN_TOKEN=$(curl -s -X POST http://127.0.0.1:8090/api/collections/_superusers/auth-with-password \
  -H "Content-Type: application/json" \
  -d '{
    "identity": "test@test.com",
    "password": "testpassword123"
  }' | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$ADMIN_TOKEN" ]; then
  echo "❌ Failed to get admin token"
  kill $PB_PID 2>/dev/null || true
  exit 1
fi

echo "✅ Admin token obtained"

# 📝 Create test_users collection via API (base type for test data)
echo "Creating test_users collection..."
cat > /tmp/test_users_collection.json <<EOF
{
  "name": "test_users",
  "type": "base",
  "fields": [
    {
      "name": "name",
      "type": "text",
      "required": true
    },
    {
      "name": "age",
      "type": "number",
      "required": true
    },
    {
      "name": "created",
      "type": "autodate",
      "onCreate": true,
      "onUpdate": false
    }
  ],
  "listRule": "@request.auth.id != \"\"",
  "viewRule": "@request.auth.id != \"\"",
  "createRule": "@request.auth.id != \"\"",
  "updateRule": "@request.auth.id != \"\"",
  "deleteRule": "@request.auth.id != \"\""
}
EOF

COLLECTION_RESPONSE=$(curl -s -X POST http://127.0.0.1:8090/api/collections \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d @/tmp/test_users_collection.json)

echo "Collection creation response: $COLLECTION_RESPONSE"

if echo "$COLLECTION_RESPONSE" | grep -q '"id"'; then
  echo "✅ test_users collection created"
else
  echo "❌ Failed to create collection"
  echo "Full response: $COLLECTION_RESPONSE"
  kill $PB_PID 2>/dev/null || true
  exit 1
fi

# Clean up temp file
rm -f /tmp/test_users_collection.json

# 👥 Create test user in the users collection (for authentication)
echo "Creating test user in users collection..."
USER_RESPONSE=$(curl -s -X POST http://127.0.0.1:8090/api/collections/users/records \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "email": "testuser@example.com",
    "password": "testuser123",
    "passwordConfirm": "testuser123",
    "name": "Test User"
  }')

if echo "$USER_RESPONSE" | grep -q '"id"'; then
  echo "✅ Test user created"
else
  echo "ℹ️ User might already exist or there was an error"
  echo "Response: $USER_RESPONSE"
fi

echo ""
echo "🎉 Setup complete!"
echo "🟢 PocketBase running at: http://127.0.0.1:8090"
echo "🔗 Admin UI: http://127.0.0.1:8090/_/"
echo "👥 Test user: testuser@example.com / testuser123"
echo "👤 Admin:     test@test.com / testpassword123"
echo ""

# 💤 Wait to keep the server running (optional: replace with your test suite call)
wait $PB_PID
