# 🔄 Migrating from Firestore to PocketBase

This guide helps you migrate from Firebase Firestore to PocketBase using the `kiss_pocketbase_repository` library.

## 🆚 Key Differences

| Aspect | Firestore | PocketBase |
|--------|-----------|------------|
| **Collections** | NoSQL documents | SQLite tables with typed fields |
| **Authentication** | Firebase Auth | Built-in auth collections |
| **Permissions** | Security Rules | JavaScript-like API Rules |
| **Real-time** | Snapshot listeners | WebSocket subscriptions |
| **Queries** | Compound queries | SQL-like filters |
| **Hosting** | Google Cloud | Self-hosted (single binary) |

## 🚀 Quick Migration Steps

### 1. Setup PocketBase Server

```bash
# Download from https://pocketbase.io
./pocketbase serve
```

### 2. Replace Firebase Dependency

```yaml
dependencies:
  # Remove these
  # firebase_core: ^2.x.x
  # cloud_firestore: ^4.x.x
  
  # Add this
  kiss_pocketbase_repository: ^1.0.0
```

### 3. Initialize Repository

```dart
// Before (Firestore)
import 'package:cloud_firestore/cloud_firestore.dart';
final firestore = FirebaseFirestore.instance;

// After (PocketBase)
import 'package:kiss_pocketbase_repository/kiss_pocketbase_repository.dart';
final repository = PocketBaseRepository(
  baseUrl: 'http://127.0.0.1:8090',
);
```

## 🔐 Authentication Migration

### Firestore Authentication
```dart
// Firebase Auth
import 'package:firebase_auth/firebase_auth.dart';

final auth = FirebaseAuth.instance;
final userCredential = await auth.signInWithEmailAndPassword(
  email: 'user@example.com',
  password: 'password123',
);
final user = auth.currentUser;
```

### PocketBase Authentication
```dart
// PocketBase Auth (built into collections)
final authData = await repository.authenticate(
  email: 'user@example.com', 
  password: 'password123',
);
final user = repository.currentUser;
```

**Key difference:** PocketBase uses auth collections instead of a separate auth service.

## 📊 CRUD Operations Migration

### Create Records

```dart
// Before (Firestore)
await FirebaseFirestore.instance
  .collection('users')
  .add({
    'name': 'John',
    'age': 30,
  });

// After (PocketBase)
await repository.create<User>(
  collectionName: 'users',
  data: User(name: 'John', age: 30),
);
```

### Read Records

```dart
// Before (Firestore)
final doc = await FirebaseFirestore.instance
  .collection('users')
  .doc('user_id')
  .get();
final user = User.fromMap(doc.data()!);

// After (PocketBase)
final user = await repository.getById<User>(
  collectionName: 'users',
  id: 'user_id',
  fromMap: User.fromMap,
);
```

### Update Records

```dart
// Before (Firestore)
await FirebaseFirestore.instance
  .collection('users')
  .doc('user_id')
  .update({'age': 31});

// After (PocketBase)
await repository.update<User>(
  collectionName: 'users',
  id: 'user_id', 
  data: user.copyWith(age: 31),
);
```

### Delete Records

```dart
// Before (Firestore)
await FirebaseFirestore.instance
  .collection('users')
  .doc('user_id')
  .delete();

// After (PocketBase)
await repository.delete(
  collectionName: 'users',
  id: 'user_id',
);
```

## 🔴 Real-time Subscriptions

### Firestore Snapshots
```dart
// Before (Firestore)
FirebaseFirestore.instance
  .collection('users')
  .snapshots()
  .listen((snapshot) {
    final users = snapshot.docs
      .map((doc) => User.fromMap(doc.data()))
      .toList();
  });
```

### PocketBase Subscriptions
```dart
// After (PocketBase)
repository.subscribe<User>(
  collectionName: 'users',
  fromMap: User.fromMap,
  onData: (users) => print('Users updated: ${users.length}'),
  onError: (error) => print('Error: $error'),
);
```

## 🛡️ Security Rules Migration

This is the biggest conceptual change when migrating.

### Firestore Security Rules
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /posts/{postId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### PocketBase API Rules
```javascript
// Set in PocketBase Admin Dashboard > Collections > users
listRule: "@request.auth.id != ''"
viewRule: "@request.auth.id != ''"  
updateRule: "id = @request.auth.id"
deleteRule: "id = @request.auth.id"

// For posts collection
listRule: ""  // Public read
viewRule: ""  // Public read
createRule: "@request.auth.id != ''"  // Auth required for write
updateRule: "author = @request.auth.id"  // Owner only
```

**Key concepts:**
- Use `@request.auth.id` instead of `request.auth.uid`
- Rules are per-collection, not per-document path
- Set rules in Admin Dashboard, not in files

## 🏗️ Data Modeling Changes

### Firestore (Schema-less)
```dart
// Firestore - flexible documents
final userData = {
  'name': 'John',
  'age': 30,
  'tags': ['developer', 'flutter'],  // Arrays work
  'metadata': {                       // Nested objects work
    'lastLogin': Timestamp.now(),
  },
};
```

### PocketBase (Typed Schema)
```dart
// PocketBase - predefined fields in Admin Dashboard
// 1. Create collection with fields:
//    - name (text)
//    - age (number) 
//    - tags (select, multiple)
//    - lastLogin (date)

// 2. Use typed models
class User {
  final String id;
  final String name;
  final int age;
  final List<String> tags;
  final DateTime lastLogin;
  
  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'],
    name: map['name'],
    age: map['age'],
    tags: List<String>.from(map['tags'] ?? []),
    lastLogin: DateTime.parse(map['lastLogin']),
  );
  
  Map<String, dynamic> toMap() => {
    'name': name,
    'age': age,
    'tags': tags,
    'lastLogin': lastLogin.toIso8601String(),
  };
}
```

## 🔍 Querying Differences

### Firestore Queries
```dart
// Firestore compound queries
final query = FirebaseFirestore.instance
  .collection('posts')
  .where('published', isEqualTo: true)
  .where('author', isEqualTo: 'user_id')
  .orderBy('created', descending: true)
  .limit(10);
```

### PocketBase Filters
```dart
// PocketBase SQL-like filters
final posts = await repository.getAll<Post>(
  collectionName: 'posts',
  fromMap: Post.fromMap,
  filter: 'published = true && author = "user_id"',
  sort: '-created',
  perPage: 10,
);
```

## 📚 Common Migration Patterns

### User Management
```dart
// Create user collection in PocketBase Admin:
// Type: auth
// Fields: name (text), avatar (file), role (select)

class AppUser {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final String role;
  
  // fromMap/toMap methods...
}
```

### File Uploads
```dart
// Before (Firestore + Storage)
final ref = FirebaseStorage.instance.ref().child('avatars/${user.uid}');
await ref.putFile(file);
final url = await ref.getDownloadURL();

// After (PocketBase built-in files)
final user = await repository.update<User>(
  collectionName: 'users',
  id: userId,
  data: user.copyWith(avatar: file), // PocketBase handles file upload
);
```

## ⚠️ Migration Considerations

### Things to be aware of:

1. **Schema Definition Required**: Unlike Firestore's flexible documents, you must define field schemas in PocketBase Admin Dashboard before using them.

2. **Self-Hosting**: PocketBase requires you to host your own server (but it's just one binary file).

3. **Different Field Types**: PocketBase has specific field types (text, number, date, file, relation, etc.) vs Firestore's flexible types.

4. **API Rules vs Security Rules**: Different syntax and evaluation context.

5. **Real-time Connection**: WebSocket-based vs Firestore's proprietary protocol.

## 🎯 Next Steps

1. **Setup PocketBase server** and create your collections
2. **Migrate authentication** - create auth collection
3. **Define data models** with typed schemas  
4. **Update CRUD operations** using repository pattern
5. **Migrate security rules** to API rules
6. **Test real-time subscriptions**

## 📖 Additional Resources

- [PocketBase Documentation](https://pocketbase.io/docs/)
- [PocketBase Admin Dashboard Guide](https://pocketbase.io/docs/admin-ui/)
- [API Rules Examples](https://pocketbase.io/docs/api-rules-and-filters/)
- [Field Types Reference](https://pocketbase.io/docs/collections/#fields)

---

**Questions about migration?** Open an issue or check the [examples](examples/) directory. 