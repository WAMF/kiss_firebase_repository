# Integration Tests for KISS Firebase Repository

This directory contains Flutter integration tests for the KISS Firebase Repository package. The tests are located in the example app to maintain proper separation between the package code and test infrastructure.

## Prerequisites

1. **Flutter SDK** - Make sure Flutter is installed and in your PATH
2. **Xcode and iOS Simulator** - Required for running tests on iOS simulator
3. **Firebase CLI** - Install with `npm install -g firebase-tools`
4. **Firebase Emulator** - The tests use the Firestore emulator

## Running Integration Tests

### Option 1: Using the provided script (Recommended)

From the **package root directory** (not example/):

```bash
./test_integration_with_emulator.sh
```

This script will:
- Check if the iOS simulator is running (and start it if needed)
- Check if the Firebase emulator is running (and start it if needed)
- Navigate to the example app directory
- Install dependencies for the example app
- Run the integration tests on the iOS simulator
- Clean up afterwards

### Option 2: Manual setup

1. Start the iOS simulator:
```bash
flutter emulators --launch apple_ios_simulator
```

2. Start the Firebase emulator (from package root):
```bash
firebase emulators:start --only firestore
```

3. Navigate to example directory and install dependencies:
```bash
cd example
flutter pub get
```

4. Set the emulator environment and run tests:
```bashini
flutter test integration_test/app_test.dart -d apple_ios_simulator
```

## What the tests cover

The integration tests verify:
- Firebase initialization and configuration
- Repository CRUD operations (Create, Read, Update, Delete)
- Batch operations (adding/deleting multiple items)
- Auto-generated Firestore IDs
- Real-time streaming of data changes
- Proper error handling
- Integration with a real Flutter app

## Test Structure

- Tests run in the context of the example Flutter app
- Each test launches the example app using `app.main()`
- Tests use a dedicated collection (`integration_test_users`) that gets cleaned up between tests
- Firebase is configured to use the local emulator for safe testing
- The package is imported as a path dependency in the example app

## Package Structure

```
kiss_firebase_repository/          # Package root
├── lib/                          # Package source code
├── test/                         # Unit tests
├── example/                      # Example Flutter app
│   ├── lib/main.dart            # Example app
│   ├── integration_test/        # Integration tests
│   │   └── app_test.dart        # Main integration test file
│   └── pubspec.yaml             # Example app dependencies
└── test_integration_with_emulator.sh  # Test runner script
```

## Troubleshooting

**Error: "PlatformException(channel-error, Unable to establish connection on channel.)"**
- Make sure the Firebase emulator is running on localhost:8080
- Verify Firebase CLI is installed and working

**Error: "No supported devices connected"**
- Make sure iOS simulator is running
- Check with `flutter devices` to see available devices
- Try starting simulator manually: `flutter emulators --launch apple_ios_simulator`

**Error: "Xcode command line tools are not installed"**
- Install with: `xcode-select --install`

**Tests fail with connection errors**
- Ensure no firewall is blocking localhost:8080
- Try restarting the Firebase emulator
- Verify iOS simulator is fully booted before running tests

**Dependency issues**
- Make sure you run the script from the package root directory
- The script automatically runs `flutter pub get` in the example directory
- Verify the package path dependency is correct in `example/pubspec.yaml`

**Simulator takes too long to boot**
- The script waits up to 2 minutes for the simulator to boot
- On slower machines, you may want to start the simulator manually first 
