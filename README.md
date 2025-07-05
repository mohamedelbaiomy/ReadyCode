# 🚀 ReadyCode
Pre-built code snippets for faster development!

## 📌 What is this repo?
ReadyCode provides ready-to-use, tested code snippets for common development tasks

<br>

## 🛡 Authentication Providers (auth_providers_service.dart)

| **Google Sign-In** | **Facebook Login** | **Sign in with Apple** | **GitHub Sign in** |
|--------------------|--------------------|------------------------|---------------------

<br>

## ⛓‍💥 **NameMethods** (`name_methods.dart`)

| Utility | Function | Example | When to Use |
|---------|----------|---------|-------------|
| **`NameMethods`** | Formats names for display | `"Mohamed Elsayed Elbaiomy"` → `"Mohamed Elbaiomy"`<br>`"Mohamed Elbaiomy"` → `"ME"` | User profiles, avatars, chat lists,...etc |

```dart
// Get shortened name (first + last)
NameMethods.getShortName("Mohamed Elsayed Elbaiomy"); 
// Returns: "Mohamed Elbaiomy"

// Get initials
NameMethods.getShortNameCharacters("Mohamed Elbaiomy");
// Returns: "ME"
```
<br>

## 🗄️ **Firestore Service** (`firestore_service.dart`)

A complete Firebase Firestore solution with 15+ ready-to-use methods for seamless database operations.

### 🔥 **Core Features**

| Method Category | Key Methods | Usage Example | Best For |
|-----------------|-------------|---------------|----------|
| **Document CRUD** | `createCollectionWithDoc` <br> `updateData` <br> `deleteData` | ``updateData(``<br>``  collectionName: 'users',``<br>``  docName: 'u123',``<br>``  data: {'lastActive': Timestamp.now()}``<br>``)`` | User profiles, app settings |
| **Subcollections** | `createSubCollectionWithDoc`<br>`updateSubCollectionDoc` | ``createSubCollectionWithDoc(``<br>``  firstCollectionName: 'users',``<br>``  secondCollectionName: 'orders',``<br>``  firstDocName: 'u123',``<br>``  secondDocName: 'o456',``<br>``  data: orderData``<br>``)`` | Nested data (comments, orders) |
| **Queries** | `getDataWithPagination`<br>`getSubCollectionDocData` | ``getDataWithPagination(``<br>``  collection: 'posts',``<br>``  limit: 20,``<br>``  lastDocument: lastDoc``<br>``)`` | Infinite scroll, feeds |
| **Batch Operations** | `deleteSubCollection` | ``deleteSubCollection(``<br>``  firstCollectionName: 'teams',``<br>``  secondCollectionName: 'members',``<br>``  docName: 't789'``<br>``)`` | Data cleanup |

### 💻 **Implementation Guide**

```dart
// Create user document on signup
Future<void> createUserProfile(User user) async {
  await FirestoreRepo.createCollectionWithDoc(
    collectionName: 'users',
    docName: user.uid,
    data: {
      'email': user.email,
      'createdAt': Timestamp.now(),
      'status': 'active'
    }
  );
}

// Paginated post loading
Future<List<Post>> loadPosts({DocumentSnapshot? lastDoc}) async {
  final snapshot = await FirestoreRepo.getDataWithPagination(
    collectionName: 'posts',
    limit: 10,
    lastDocument: lastDoc,
  );
  return snapshot.docs.map((doc) => Post.fromJson(doc.data())).toList();
}
```

<br>

## 🔐 Auth Service (`auth_service.dart`)

A **production-grade Firebase authentication wrapper** that simplifies user management while maintaining security best practices.

| Category | Methods | Description |
|----------|---------|-------------|
| **Authentication** | `signInWithEmailAndPassword()`<br>`signUpWithEmailAndPassword()`<br>`logOut()` | Core login/logout flows |
| **Verification** | `sendEmailVerification()`<br>`checkEmailVerification()` | Email confirmation system |
| **Password** | `sendPasswordResetEmail()`<br>`updateUserPassword()`<br>`checkOldPassword()` | Secure password management |
| **User Info** | `updateUserName()`<br>`reloadUserData()`<br>`currentUser` | Profile management |

## 💻 Basic Usage

```dart
// Sign up new user
await AuthRepo.signUpWithEmailAndPassword(
  email: 'mohamedelbaiomy262003@gmail.com',
  password: '123456'
);

// Sign in existing user
await AuthRepo.signInWithEmailAndPassword(
  email: 'mohamedelbaiomy262003@gmail.com',
  password: '123456'
);

// Sign out
await AuthRepo.logOut();

// Send verification email
await AuthRepo.sendEmailVerification();

// Check verification status
if (!await AuthRepo.checkEmailVerification()) {
  // Show "Verify Email" reminder
}

// Password reset
await AuthRepo.sendPasswordResetEmail(email: 'mohamedelbaiomy262003@gmail.com');

// Update password (after reauthentication)
await AuthRepo.updateUserPassword(newPassword: '123456');

// Combine with Firestore for complete user management
Future<void> createUserProfile() async {
  final user = AuthRepo.currentUser!;
  await FirestoreRepo.createCollectionWithDoc(
    collectionName: 'users',
    docName: user.uid,
    data: {
      'email': user.email,
      'name': user.displayName,
      'createdAt': Timestamp.now()
    }
  );
}

```

<br>


## 🪄 KeepAlivePage (keep_alive_page.dart)
A Flutter utility widget that preserves the state of its child widget when navigating away (e.g., in TabBarView, PageView, or stacked routes). Prevents unnecessary rebuilds and maintains scroll positions/form data.

| Utility | Function | Example | When to Use |
|---------|----------|---------|-------------|
| **`KeepAlivePage`** | Preserves widget state | Maintains scroll position/form data between tab switches | TabViews, PageViews, complex forms |

How to use ?

🔹Wraps any widget with KeepAlivePage.

<br>

### Star ⭐ the repo if you find these useful!

<br>

### 🤝 Contribute
Feel free to:

🔹 Open an Issue (bug reports/feature requests)🔹 Submit a PR

