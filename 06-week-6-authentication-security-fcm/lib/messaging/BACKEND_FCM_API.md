# 📡 FCM Backend API Reference

Panduan untuk **backend developer** yang ingin mengirim notifikasi FCM ke Campus Notify App.

---

## 🔑 Prerequisites

Backend Anda membutuhkan:

1. **Firebase Project ID** - Dari Firebase Console
2. **Server API Key** atau **Private Key (JSON)** - Untuk authenticate ke FCM
3. **Device Token** - Dari app (dikirim via POST `/devices`)
4. **HTTP Client** - cURL, Postman, Python requests, Node.js, dll

---

## 📍 Get Firebase Server Credentials

### Step 1: Buka Firebase Console

```
https://console.firebase.google.com/
→ Select Project: campus_notify
→ Project Settings (⚙️)
```

### Step 2: Generate Private Key

Pilih tab **"Service Accounts"**:
```
┌────────────────────────────────────────┐
│ Service Accounts                       │
│                                        │
│ Firebase Admin SDK                     │
│ ┌────────────────────────────────────┐ │
│ │ [Generate new private key]         │ │
│ └────────────────────────────────────┘ │
│                                        │
│ ✓ Downloaded as JSON file             │
│   Simpan dengan aman!                  │
└────────────────────────────────────────┘
```

**Save:** `campus_notify_firebase_key.json`

Isi file:
```json
{
  "type": "service_account",
  "project_id": "campus-notify-12345",
  "private_key_id": "a1b2c3d4e5f6...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  "client_email": "firebase-adminsdk-xxxx@campus-notify-12345.iam.gserviceaccount.com",
  "client_id": "123456789....",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

---

## 🚀 Send Notification via FCM API

### Menggunakan Firebase Admin SDK (Recommended)

#### A. Python (Flask/Django)

```python
import firebase_admin
from firebase_admin import credentials, messaging

# Initialize Firebase
cred = credentials.Certificate('campus_notify_firebase_key.json')
firebase_admin.initialize_app(cred)

# Send notification ke TOPIC
message = messaging.Message(
    notification=messaging.Notification(
        title='Pengumuman Penting',
        body='Cek pengumuman akademik terbaru',
    ),
    data={
        'route': '/pengumuman/123',
        'announcement_id': '123',
    },
    topic='pengumuman-kampus',  # Broadcast ke semua subscriber
)

response = messaging.send(message)
print(f'Message sent successfully: {response}')
```

#### B. Node.js (Express)

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./campus_notify_firebase_key.json');

// Initialize Firebase
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Send notification ke TOPIC
const message = {
  notification: {
    title: 'Pengumuman Penting',
    body: 'Cek pengumuman akademik terbaru',
  },
  data: {
    route: '/pengumuman/123',
    announcement_id: '123',
  },
  topic: 'pengumuman-kampus',  // Broadcast ke semua subscriber
};

admin.messaging().send(message)
  .then((response) => {
    console.log('Message sent successfully:', response);
  })
  .catch((error) => {
    console.log('Error sending message:', error);
  });
```

#### C. Java/Spring Boot

```java
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;

public class FCMService {
    public void sendNotification(String topic, String title, String body, String route) {
        try {
            Message message = Message.builder()
                .setNotification(Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build())
                .putData("route", route)
                .putData("announcement_id", "123")
                .setTopic(topic)  // e.g., "pengumuman-kampus"
                .build();

            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println("Message sent successfully: " + response);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

---

### Menggunakan HTTP API (Direct POST)

#### Endpoint

```
POST https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send

Headers:
- Authorization: Bearer {ACCESS_TOKEN}
- Content-Type: application/json
```

#### Get Access Token

```bash
# Menggunakan gcloud CLI
gcloud auth application-default print-access-token

# Atau gunakan private key untuk generate token
curl -X POST "https://oauth2.googleapis.com/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer" \
  -d "assertion={SIGNED_JWT}"
```

#### Request Body - Send to TOPIC

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": {
      "title": "Pengumuman Penting",
      "body": "Cek pengumuman akademik terbaru"
    },
    "data": {
      "route": "/pengumuman/123",
      "announcement_id": "123",
      "timestamp": "2024-10-04T10:30:00Z"
    }
  }
}
```

#### Request Body - Send to DEVICE TOKEN

```json
{
  "message": {
    "token": "cXB3OjIzNzI0NjplLXQyVjhDQU1FMDZfQlJCRkw6MDo...",
    "notification": {
      "title": "Notifikasi Personal",
      "body": "Ini notifikasi hanya untuk Anda"
    },
    "data": {
      "route": "/pengumuman/456",
      "user_id": "student_123"
    }
  }
}
```

#### Response

**Success (200 OK):**
```json
{
  "name": "projects/campus-notify-12345/messages/1234567890123456789"
}
```

**Error (400+):**
```json
{
  "error": {
    "code": 400,
    "message": "Invalid argument",
    "status": "INVALID_ARGUMENT"
  }
}
```

---

## 📲 Device Registration Endpoint

App akan POST device token ke backend Anda. Setup endpoint ini:

### Endpoint

```
POST /api/v1/devices
Content-Type: application/json

{
  "fcm_token": "cXB3OjIzNzI0NjplLXQyVjhDQU1FMDZfQlJCRkw6MDo...",
  "platform": "android" atau "ios",
  "user_id": "student_123",  // optional, jika app sudah login
  "device_name": "Pixel 6",   // optional
  "timestamp": "2024-10-04T10:30:00Z"
}
```

### Backend Implementation

**Python Flask:**
```python
@app.route('/api/v1/devices', methods=['POST'])
def register_device():
    data = request.json
    fcm_token = data.get('fcm_token')
    platform = data.get('platform')
    user_id = data.get('user_id')
    
    # Save ke database
    device = Device(
        fcm_token=fcm_token,
        platform=platform,
        user_id=user_id,
        created_at=datetime.now()
    )
    db.session.add(device)
    db.session.commit()
    
    return jsonify({'status': 'success', 'device_id': device.id}), 201
```

**Node.js Express:**
```javascript
app.post('/api/v1/devices', async (req, res) => {
  try {
    const { fcm_token, platform, user_id } = req.body;
    
    // Validate
    if (!fcm_token) {
      return res.status(400).json({ error: 'fcm_token required' });
    }
    
    // Save to database
    const device = await Device.create({
      fcm_token,
      platform,
      user_id,
      createdAt: new Date(),
    });
    
    res.status(201).json({ status: 'success', device_id: device.id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

---

## 🔄 Token Refresh Handling

⚠️ **PENTING:** Backend harus handle token refresh!

Token bisa berubah saat:
- User uninstall & reinstall app
- User clear app data
- Google security update (token rotation)

**Solusi:**
1. Jangan cache token di backend selamanya
2. Implement token refresh endpoint:
   ```
   DELETE /api/v1/devices/{old_token}
   POST /api/v1/devices (dengan token baru)
   ```

3. Implement retry logic saat send FCM:
   ```python
   try:
       send_fcm(old_token)
   except TokenExpiredError:
       # Remove old token dari DB
       delete_token_from_db(old_token)
       # Notify user atau retry dengan token baru
   ```

---

## 📊 Notification Types

### 1. Broadcast (Semua User)

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": {
      "title": "Pengumuman Akademik",
      "body": "Perubahan jadwal kuliah semester genap"
    },
    "data": {
      "route": "/pengumuman/999"
    }
  }
}
```

**Use Case:** Pengumuman penting untuk semua mahasiswa

---

### 2. Personal (Specific User)

```json
{
  "message": {
    "token": "USER_FCM_TOKEN_HERE",
    "notification": {
      "title": "Nilai Anda",
      "body": "UAS Matakuliah X telah diternilai"
    },
    "data": {
      "route": "/pengumuman/123"
    }
  }
}
```

**Use Case:** Notifikasi personal (nilai, tagihan, reminder)

---

### 3. Segmented (Specific Group)

```python
# Send to multiple devices (Android)
registration_tokens = [
    'token1_mahasiswa_angkatan_2022',
    'token2_mahasiswa_angkatan_2022',
    'token3_mahasiswa_angkatan_2022',
]

message = messaging.MulticastMessage(
    notification=messaging.Notification(
        title='Pengumuman Angkatan 2022',
        body='Jadwal wisuda telah diumumkan',
    ),
    data={'route': '/pengumuman/888'},
    tokens=registration_tokens,
)

response = messaging.send_multicast(message)
```

**Use Case:** Notifikasi untuk angkatan tertentu, UKM tertentu, etc.

---

## 🔐 Best Practices

### 1. Validate Token Before Sending
```python
# Check if token is valid (exists in DB & not expired)
device = Device.query.filter_by(fcm_token=token).first()
if not device:
    return error('Token not found')
```

### 2. Implement Retry Logic
```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10)
)
def send_fcm_with_retry(token, message):
    return messaging.send(message)
```

### 3. Log All Notifications
```python
notification_log = NotificationLog(
    recipient_token=token,
    title=title,
    body=body,
    data=data,
    status='sent',
    sent_at=datetime.now(),
    response=response
)
db.session.add(notification_log)
db.session.commit()
```

### 4. Batch Processing (untuk volume besar)
```python
# Jangan kirim one-by-one, batch ke 500 maksimal
tokens = get_all_device_tokens()  # 10,000 devices

for i in range(0, len(tokens), 500):
    batch = tokens[i:i+500]
    message = messaging.MulticastMessage(
        topic='pengumuman-kampus',
        tokens=batch,
        # notification + data
    )
    messaging.send_multicast(message)
```

---

## 🧪 Testing dengan cURL

```bash
# 1. Set access token
TOKEN=$(gcloud auth application-default print-access-token)

# 2. Send test notification
curl -X POST \
  "https://fcm.googleapis.com/v1/projects/campus-notify-12345/messages:send" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "topic": "pengumuman-kampus",
      "notification": {
        "title": "Test Notifikasi",
        "body": "Ini adalah test dari backend"
      },
      "data": {
        "route": "/pengumuman/999"
      }
    }
  }'

# Response:
# {"name":"projects/campus-notify-12345/messages/1..."}
```

---

## 📈 Monitoring & Analytics

Firebase Console → Analytics:
```
Cloud Messaging → Notifications
  ├── Delivery rate (berapa % device menerima)
  ├── Open rate (berapa % user tap notification)
  ├── Engagement (waktu rata-rata user buka setelah tap)
  └── Crashes (apakah ada crash saat menerima notif)
```

---

## ❌ Common Errors & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `INVALID_ARGUMENT` | Format JSON salah | Validate JSON structure |
| `NOT_FOUND` | Token tidak terdaftar | Device perlu register lagi |
| `PERMISSION_DENIED` | Private key expired | Regenerate private key |
| `RESOURCE_EXHAUSTED` | Rate limit exceeded | Implement backoff retry |
| `UNAUTHENTICATED` | Access token invalid | Refresh access token |

---

## 📚 Reference

- [FCM HTTP API Docs](https://firebase.google.com/docs/cloud-messaging/send-message)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [FCM Android Integration](https://firebase.google.com/docs/cloud-messaging/android/client)

---

**Questions?** Ref ke `IMPLEMENTATION_GUIDE.md` atau `push_service.dart` di app-side.
