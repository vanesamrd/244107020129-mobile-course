# 📌 FCM Cheatsheet - Quick Reference

Bookmark atau print halaman ini untuk akses cepat! ⚡

---

## 🔥 FCM Status Check

```bash
# 1. Run app & check token
flutter run

# Expected output:
# [PushService] Token init: a1b2c3d4e5f6g7h8i9j0...
# [PushService] Subscribed: pengumuman-kampus

# 2. Monitor logs
flutter logs | grep "PushService"

# 3. Check Firebase Console
# https://console.firebase.google.com/
# → Project: campus_notify
# → Cloud Messaging

# 4. Send test notification
# Firebase Console → Compose → Send
```

---

## 📲 Test Scenarios (30 seconds each)

### Foreground (App Open)
```
1. flutter run
2. Keep app open (don't minimize)
3. Firebase Console → Compose → Send to topic
4. Expected: Banner pops up on screen
5. Tap: Navigate to /pengumuman/123
```

### Background (App Minimized)
```
1. flutter run
2. Press HOME button
3. Firebase Console → Compose → Send
4. Pull down notification tray (top of screen)
5. Tap notification
6. Expected: App opens & navigates
```

### Terminated (App Killed)
```
1. flutter run
2. Swipe up from Recent Apps to close
3. Firebase Console → Compose → Send
4. Tap notification from tray
5. Expected: App launches & auto-navigates
```

---

## 💻 Code Reference (Copy-Paste)

### Use Route Constant
```dart
// ✅ CORRECT
context.go(AppRoutes.announcementDetail(id: '123'));
context.go(AppRoutes.home);
context.go(AppRoutes.pushServiceDemo);

// ❌ WRONG (DON'T DO THIS)
context.go('/pengumuman/123');
context.go('/');
context.go('/demo');
```

### Send FCM from Backend (Python)
```python
import firebase_admin
from firebase_admin import credentials, messaging

cred = credentials.Certificate('firebase_key.json')
firebase_admin.initialize_app(cred)

message = messaging.Message(
    notification=messaging.Notification(
        title='Pengumuman',
        body='Update terbaru',
    ),
    data={'route': '/pengumuman/123'},
    topic='pengumuman-kampus',
)

messaging.send(message)
```

### POST Device Token (Backend)
```python
# App sends POST to this endpoint:
# POST /api/v1/devices
# Body:
# {
#   "fcm_token": "a1b2c3d4...",
#   "platform": "android" or "ios"
# }

@app.route('/api/v1/devices', methods=['POST'])
def register_device():
    token = request.json.get('fcm_token')
    platform = request.json.get('platform')
    
    # Save to DB
    Device.create(fcm_token=token, platform=platform)
    
    return {'status': 'success'}, 201
```

---

## 🆘 Troubleshooting (5-min solutions)

| Problem | Solution |
|---------|----------|
| **Notif tidak muncul di foreground** | Check `listenForeground()` di `main.dart` initState |
| **Token is null** | Restart device, check internet, reinstall app |
| **"Firebase not initialized"** | Check `await Firebase.initializeApp()` di `main.dart` before PushService init |
| **Android notif no banner** | Check `Importance.high` di `AndroidNotificationChannel` |
| **iOS notif not working** | Check APNs key uploaded to Firebase Console |
| **Deep link not navigating** | Check route format matches `AppRoutes.announcementDetail()` |
| **Token shows in console but Firebase Console says "no subscribers"** | Wait 5 seconds, refresh browser |

---

## 📋 Setup Checklist (First Time)

```
Firebase Console:
□ Create project at https://console.firebase.google.com/
□ Register Android app
□ Download google-services.json → android/app/
□ Upload APNs key (iOS): Project Settings → Cloud Messaging
□ Copy Project ID (for API calls)

Android:
□ android/app/src/main/AndroidManifest.xml has POST_NOTIFICATIONS permission
□ android/app/build.gradle.kts has google-services plugin
□ Run: flutter clean && flutter pub get

App:
□ routes.dart exists in lib/
□ push_service.dart in lib/messaging/
□ main.dart imports push_service.dart & routes.dart
□ Run: flutter run

Test:
□ Token prints in console logs
□ Can send from Firebase Console
□ Notifications appear on device
```

---

## 🔗 Links (Bookmarks)

```
Firebase Console:
https://console.firebase.google.com/

Firebase Docs:
https://firebase.flutter.dev/docs/messaging/overview/

Google Cloud Messaging API:
https://firebase.google.com/docs/cloud-messaging/auth-server

Android Package Name Location:
android/app/build.gradle.kts → namespace / applicationId
```

---

## 📊 FCM Payload Templates

### Minimal (Broadcast)
```json
{
  "to": "/topics/pengumuman-kampus",
  "notification": {
    "title": "Update",
    "body": "Ada update terbaru"
  }
}
```

### Full (Broadcast with Deep Link)
```json
{
  "to": "/topics/pengumuman-kampus",
  "notification": {
    "title": "Pengumuman Penting",
    "body": "Lihat detail pengumuman akademik"
  },
  "data": {
    "route": "/pengumuman/123",
    "id": "123"
  }
}
```

### Personal (Device Token)
```json
{
  "to": "cXB3OjIzNzI0NjplLXQyVjhDQU1FMDZfQlJCRkw6MDo...",
  "notification": {
    "title": "Notifikasi Khusus",
    "body": "Ini notifikasi personal untuk Anda"
  },
  "data": {
    "route": "/pengumuman/456"
  }
}
```

---

## 🎯 Environment Variables (Backend)

```bash
# .env file di backend
FIREBASE_PROJECT_ID=campus-notify-12345
FIREBASE_PRIVATE_KEY_ID=a1b2c3d4e5f6...
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@campus-notify-12345.iam...
FIREBASE_AUTH_URI=https://accounts.google.com/o/oauth2/auth
FIREBASE_TOKEN_URI=https://oauth2.googleapis.com/token
```

---

## 📱 Terminal Commands

```bash
# Quick start
cd /project
flutter clean
flutter pub get
flutter run

# Monitor FCM logs only
flutter logs | grep -E "PushService|FCM"

# Build APK (for Android testing)
flutter build apk --debug

# Build IPA (for iOS testing)
flutter build ipa --debug

# Run on specific device
flutter run -d <device-id>

# List connected devices
flutter devices
```

---

## 🧪 Testing Endpoints (cURL)

```bash
# Get Firebase access token
TOKEN=$(gcloud auth application-default print-access-token)

# Send test message
curl -X POST \
  "https://fcm.googleapis.com/v1/projects/campus-notify-12345/messages:send" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "topic": "pengumuman-kampus",
      "notification": {
        "title": "Test",
        "body": "Test notification"
      },
      "data": {"route": "/pengumuman/999"}
    }
  }'
```

---

## 💡 Pro Tips

1. **Save token to file for testing**
   ```dart
   // In homepage, add button:
   // "Copy Token to Clipboard"
   // Then paste wherever needed
   ```

2. **Monitor token changes**
   ```bash
   flutter logs | grep "Token"
   # Shows init token + all refresh events
   ```

3. **Use Firebase Emulator (local)**
   ```bash
   firebase emulators:start --only messaging
   # Good for development without hitting production
   ```

4. **Batch send to multiple users**
   ```python
   # In backend, use MulticastMessage
   # Can send to 500 devices at once
   # Better than loop + individual sends
   ```

5. **Log all notifications**
   ```python
   # In backend notification logger
   # Track: sent_at, recipient, status, response
   # Helpful for debugging
   ```

---

## ⏰ Expected Times

| Task | Time |
|------|------|
| Firebase Console setup | 15 min |
| Download google-services.json | 2 min |
| Setup Android/iOS config | 10 min |
| Run first test | 5 min |
| Test all 3 scenarios | 10 min |
| Setup backend endpoint | 20 min |
| **Total** | **~60 min** |

---

## 📞 Quick Help

```
❓ "Token tidak muncul"
→ Check internet on device
→ Check Firebase initialized before PushService
→ Restart: flutter clean + flutter run

❓ "Notif dapat di Firebase tapi tidak di app"
→ Check permission granted (iOS/Android 13+)
→ Check listenForeground() di main.dart
→ Check device language ≠ notification language setting

❓ "Deep link tidak jalan"
→ Check route format matches /pengumuman/:id
→ Check AppRoutes.isValidRoute(route) returns true
→ Check data payload: {"route": "/pengumuman/123"}

❓ "Backend can't send FCM"
→ Check Project ID di Firebase Console (copy correctly)
→ Check Private Key file (not expired, valid JSON)
→ Check token format (harus string panjang, bukan null)
→ Try: Test send dari Firebase Console dulu
```

---

## ✅ Production Checklist

```
Before pushing to production:

Testing:
□ Test on physical device (iOS + Android)
□ Test all 3 states (Foreground/Background/Terminated)
□ Test deep links from FCM
□ Test with real backend API

Security:
□ Private key stored in secure env var (not in code)
□ API endpoints require authentication
□ Rate limiting on /devices endpoint
□ Log notification payload (no PII)

Monitoring:
□ Backend logs all FCM sends
□ Track delivery rate
□ Track open rate
□ Alert on send failures

Performance:
□ Batch send to 500+ devices at once
□ Implement retry with exponential backoff
□ Cleanup old device tokens regularly
```

---

**Bookmarked? Check! 📌**

👉 Read more: Open `lib/messaging/INDEX.md` for full documentation links.

**Last Update:** October 4, 2026 ✅
