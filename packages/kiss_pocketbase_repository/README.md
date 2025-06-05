<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# PocketBase Repository

A PocketBase implementation of the `kiss_repository` interface.

## Overview

This package provides a clean and simple repository interface for PocketBase, following the KISS (Keep It Simple, Stupid) principle. It implements the same `Repository<T>` interface as `kiss_firebase_repository`, allowing you to easily switch between PocketBase and Firebase backends.

## ✨ Features

- ✅ Simple repository interface for CRUD operations
- ✅ Type-safe data conversions between Dart and PocketBase
- ✅ Support for batch operations
- ✅ Real-time streaming with PocketBase subscriptions
- ✅ Flexible query building
- ✅ Auto-generated PocketBase IDs
- ✅ Built-in error handling
- ✅ Pure Dart package (works in any Dart environment)

## 🎯 PocketBase Essentials for Developers

### Collections & Schemas
- PocketBase uses predefined field schemas
- Create collections in Admin Dashboard first
- Types: `base` (data), `auth` (users), `view` (read-only)

### Authentication Architecture

**🔐 Authentication Collections**

PocketBase handles user authentication through specialized collections:

1. **Auth Collections as User Storage**
   - Mark collection as `auth` type in Admin Dashboard  
   - Includes built-in fields: `email`, `password`, `verified`, `tokenKey`
   - Add custom fields: `name`, `avatar`, `department`
   - **Replaces traditional role systems** - collections can act as broad role types (`admins`, `staff`, `customers`) or use role fields within collections

2. **User Record Creation**
   - Admin Dashboard interface
   - API calls with administrative privileges
   - Self-registration (controlled by `createRule`)

### Permission Model
```javascript
// Reference collection type (broad roles)
createRule: "@request.auth.collectionName = 'staff'"

// Reference role fields (granular roles)  
deleteRule: "@request.auth.role = 'admin'"

// Combined approach
updateRule: "@request.auth.collectionName = 'staff' && @request.auth.role = 'manager'"
```

### Practical Workflow
1. Create collections in Admin Dashboard
2. Define API rules for permissions  
3. Use repository library for CRUD operations

**💡 Key Concept:** Auth collections replace traditional user/role tables with flexible, rule-driven permissions.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  kiss_pocketbase_repository: ^0.1.0
```

## Usage

*Coming soon - implementation in progress*

## Status

🚧 **Under Development** - This package is currently being implemented.

See the [implementation plan](../../docs/pocketbase.md) for details.

## License

MIT License
