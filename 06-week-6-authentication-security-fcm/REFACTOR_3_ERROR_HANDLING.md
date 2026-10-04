## 🛡️ Refactoring #3: Error Handling Layer + Integration Tests

**Status:** ✅ Complete  
**Date:** 2024  
**All Tests Passing:** 61/61 ✓

---

## 📋 What Was Done

### 1. **Error Handling Layer** (`lib/data/api_errors.dart`)

Created a centralized error mapper transforming technical `DioException` into user-friendly messages.

**Key Features:**
- Maps all DioException types (401, timeout, offline, server errors)
- Returns Indonesian-ready messages for UI display
- Helper functions: `isAuthenticationError()`, `isNetworkError()`, `isServerError()`
- Prevents raw exceptions from leaking to UI layers

**Error Categories Handled:**
| Error | Status | Message | Use Case |
|-------|--------|---------|----------|
| 401 Unauthorized | ⚠️ Auth | "Sesi Anda telah berakhir. Silakan login kembali." | Token expired |
| 403 Forbidden | ⚠️ Auth | "Anda tidak memiliki akses ke resource ini." | Permission denied |
| 404 Not Found | ⚠️ Client | "Data yang dicari tidak ditemukan." | Resource missing |
| 500 Server Error | 🔴 Server | "Server mengalami error. Coba lagi nanti." | Backend crash |
| 503 Unavailable | 🔴 Server | "Server sedang maintenance. Coba lagi nanti." | Maintenance window |
| **timeout** | 🌐 Network | "Koneksi timeout. Jaringan Anda lambat atau terputus." | Slow network |
| **offline** | 🌐 Network | "Tidak ada koneksi internet. Periksa WiFi atau data seluler." | No connection |

**Usage Example:**
```dart
try {
  await authRepository.login(email, password);
} catch (e) {
  final message = getErrorMessage(e);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

### 2. **Integration Tests** (`test/auth_push_test.dart`)

Comprehensive unit tests for **auth + FCM message flow** without Firebase mocking.

**Test Coverage:** 32 tests organized into 7 groups

#### Group 1: Message Route Parsing (5 tests)
- ✅ Valid routes extracted correctly
- ✅ Whitespace trimmed from route strings
- ✅ Missing routes fall back to home '/'
- ✅ Invalid formats fall back to home '/'
- ✅ Empty routes fall back to home '/'

#### Group 2: Message Data Extraction (6 tests)
- ✅ Announcement ID extraction (snake_case key: `announcement_id`)
- ✅ Whitespace trimmed from IDs
- ✅ Null returned for missing IDs
- ✅ All metadata extracted except route key
- ✅ Empty data returns empty metadata map

#### Group 3: Error Handling (7 tests)
- ✅ 401 → user-friendly "login again" message
- ✅ Timeout → "network is slow" message
- ✅ Offline → "no internet" message
- ✅ 500 → server error message
- ✅ `isAuthenticationError()` detects 401
- ✅ `isNetworkError()` detects timeouts
- ✅ `isServerError()` detects 5xx errors

#### Group 4: Fake Token Store (6 tests)
- ✅ Access token storage/retrieval
- ✅ Refresh token storage/retrieval
- ✅ Token clearing works
- ✅ Token existence check
- ✅ Not logged in without token
- ✅ Logged in with valid token

#### Group 5: Token Refresh Flow (3 tests)
- ✅ Successful token refresh updates access token
- ✅ Failed refresh clears session (forces re-login)
- ✅ Multiple 401s only allow 1 refresh attempt (prevents loop)

#### Group 6: Route Constants Validation (3 tests)
- ✅ All required route constants exist
- ✅ `announcementDetail()` generates valid paths
- ✅ `isValidRoute()` validates correct formats

#### Group 7: Integration Tests (2 tests)
- ✅ FCM message with route → extracts all data for navigation
- ✅ FCM message without route → falls back to home

**Test Helpers:**
- `FakeTokenStore` - mock token persistence (no actual secure_storage)
- `FakeAuthService` - mock auth operations (login, token refresh)

---

## 🔐 Security Features

### Token Storage Security
```dart
✅ Tokens ONLY in flutter_secure_storage (encrypted)
✅ Never logged via print/debugPrint in production
✅ Cleared on logout/session expiry
✅ Auto-refresh via onTokenRefresh listener
✅ Max 1 refresh attempt to prevent 401 loops
```

### Refresh Token Loop Prevention
```dart
// The refresh flow:
1. Get 401 response
2. Call refreshToken() → Attempt 1 (OK)
3. If still 401, refreshAttempts >= 1 → Return false
4. Clear session + Force route to /login
5. No infinite loop ✓
```

---

## 📊 Test Results

**Total Tests:** 61  
**Passed:** 61 ✓  
**Failed:** 0  
**Coverage:** Message parsing, Error handling, Auth flow, Token management

```
auth_push_test.dart:           32 tests ✓
message_parser_test.dart:      29 tests ✓
Total:                         61 tests ✓
```

---

## 🔄 Integration Points

### 1. In `auth_repository.dart` - Apply error mapping:
```dart
Future<void> login(String email, String password) async {
  try {
    final response = await dio.post('/login', data: {
      'email': email,
      'password': password,
    });
    // Handle success
  } catch (e) {
    final userMessage = getErrorMessage(e);
    rethrow Exception(userMessage); // Or return AppError
  }
}
```

### 2. In `push_service.dart` - Already handles:
```dart
// Routes validated via AppRoutes.isValidRoute()
// Message data extracted via message_parser functions
// No changes needed - already integrated ✓
```

### 3. In UI Layers - Display friendly messages:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(getErrorMessage(exception))),
);
ScrollMessage(getErrorMessage(exception)); // or Dialog
```

---

## ✅ Verification Checklist

Run this checklist to ensure everything is working:

### Phase 1: Build & Compile
```bash
# ✅ No compilation errors
flutter analyze

# ✅ All tests passing
flutter test test/auth_push_test.dart
flutter test test/messaging/message_parser_test.dart
flutter test  # All tests
```

### Phase 2: Token Security
```
✅ Token stored ONLY in flutter_secure_storage
✅ Not in print() console logs
✅ Not in SharedPreferences
✅ Not in pubspec.lock (no hardcoded tokens)
✅ Cleared on 401 response
```

### Phase 3: 401 Error Handling
```
✅ 401 → Call refreshToken() automatically
✅ Refresh succeeds → Retry original request
✅ Refresh fails (still 401) → Clear session + Go to /login
✅ Maximum 1 refresh attempt (no loops)
✅ User sees friendly message, not technical error
```

### Phase 4: FCM 3-State Testing
Can you trigger these 3 scenarios and verify correct behavior?

#### 1. **Foreground** - App is open
```kotlin
// Send FCM message via Firebase Console
Expected:
  • Notification banner shows (requires requestPermission + foreground handler)
  • Message data is processed via message_parser
  • User can tap to navigate via routeFromMessage()
```

#### 2. **Background** - App is minimized
```kotlin
// Send FCM message
Expected:
  • System notification appears (Android/iOS native)
  • Tap notification → App opens
  • getInitialMessage() called in handleTerminated()
  • User routed to announcement via data.route
```

#### 3. **Terminated** - App is force-closed
```kotlin
// Force close app (swipe from recent, or Settings > Force close)
// Send FCM message
// User taps notification
Expected:
  • App launches fresh
  • getInitialMessage() called (not null)
  • User routed directly to announcement
  • No error, clean navigation ✓
```

### Phase 5: Topic vs Token Usage
```
✅ Public announcements → Send to topic "pengumuman-kampus"
   - Subscribe all users automatically (in initializeMessaging)
   - No individual tokens needed
   - cost efficient ✓

✅ Personal notifications → Send to individual device token
   - Stored on backend per user
   - Retrieved via onTokenRefresh listener
   - For user-specific alerts/messages only

✅ Verify in Firebase Console:
   - Check "Cloud Messaging" > "Send test message"
   - Select Topic "pengumuman-kampus"
   - Users get notification automatically
```

### Phase 6: Network Error Scenarios
Test these network errors and verify user-friendly messages:

| Scenario | How to Test | Expected Message |
|----------|-------------|------------------|
| No internet | Airplane mode ON | "Tidak ada koneksi..." |
| Slow network | Dev Tools > Throttle | "Koneksi timeout..." |
| Server down | Mock API crash | "Server mengalami error..." |
| Unauthorized | Send invalid token | "Sesi Anda telah..." |
| Not found | Query deleted resource | "Data tidak ditemukan..." |

---

## 📁 Files Created/Modified

| File | Status | Purpose |
|------|--------|---------|
| `lib/data/api_errors.dart` | ✅ NEW | Maps DioException to user messages |
| `test/auth_push_test.dart` | ✅ NEW | 32 integration tests (no Firebase) |
| `test/messaging/message_parser_test.dart` | ✏️ UPDATED | Fixed alphanumeric ID test |

---

## 🚀 Next Steps

After verification, this error layer is **production-ready**:

### Before Production:
1. **Add to auth_repository.dart:**
   ```dart
   import 'package:campus_notify/data/api_errors.dart';
   
   Future<void> login(...) async {
     try {
       // ... API call
     } catch (e) {
       final message = getErrorMessage(e);
       // Show to user or propagate
     }
   }
   ```

2. **Add analytics tracking (optional):**
   ```dart
   final errorCode = getErrorCode(exception);
   analytics.logEvent('auth_error', {'code': errorCode});
   ```

3. **Test in emulator/device thoroughly** before release

### Documentation:
- ✅ Error handling guide complete (api_errors.dart comments)
- ✅ Test patterns documented (auth_push_test.dart comments)
- ✅ Verification checklist provided (above)

---

## 📝 Summary

**Refactoring #3** completes the FCM implementation with:
- ✅ Centralized, user-friendly error handling
- ✅ Comprehensive auth + push integration tests (no Firebase mocking)
- ✅ 401 loop prevention mechanism
- ✅ Clear token security patterns
- ✅ Verification checklist for production deployment

**All tests passing:** 61/61 ✓  
**No errors:** ✓  
**Ready for:** auth_repository integration + production testing

---

**Status:** 🎉 **REFACTORING #3 COMPLETE** 🎉
