
# ☁️ TruckTalk Supabase Schema & API Reference

This file defines the REST API endpoints, data models, and authentication flow used by the TruckTalk mobile app via Supabase. It should be used alongside the SwiftUI development documentation for all backend-related integration work.

---

## 🔑 Supabase Credentials

- **Project URL:** `https://pvstwthufbertinmojuk.supabase.co`
- **Public anon key:**
  ```
  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2c3R3dGh1ZmJlcnRpbm1vanVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcwOTI2NDQsImV4cCI6MjA2MjY2ODY0NH0.PG7BJeWuYe-piU_JatbBfauK-I3d9sVh-2fJypAZHS8
  ```

---

## 📘 Lessons Table

- **Endpoint:** `/rest/v1/lessons`
- **Headers Required:**
  - `apikey: <anon_key>`
  - `Authorization: Bearer <access_token>`

- **Model:**
```swift
struct Lesson: Codable, Identifiable {
    let id: Int
    let title: String
    let day: Int
    let audio_url: String?
}
```

---

## 🚨 Emergency Phrases Table

- **Endpoint:** `/rest/v1/emergency_phrases`
- **Headers Required:**
  - `apikey: <anon_key>`
  - `Authorization: Bearer <access_token>`

- **Model:**
```swift
struct EmergencyPhrase: Codable, Identifiable {
    let id: Int
    let category: String
    let english: String
    let translation: String
    let audio_url: String?
}
```

---

## 👤 Auth (Email + Password)

- **Sign Up:** `POST /auth/v1/signup`
- **Login:** `POST /auth/v1/token`
- **Headers:** `apikey: <anon_key>`
- **Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

- **Response:** Includes `access_token`, `refresh_token`, and user metadata

---

## 🛠 Usage Tips

- All REST calls use `https://pvstwthufbertinmojuk.supabase.co`
- Always include the `apikey` and `Authorization` headers
- Store `access_token` securely using `AppStorage` or `Keychain`
- Prefer using `async/await` and URLSession in Swift

---

## 📌 Future Tables to Add

- `user_progress` (for lesson tracking)
- `favorites` (saved emergency phrases)
- `downloads` (for offline prefetch tracking)

---

**Use this file as your definitive reference for connecting the TruckTalk iOS app to Supabase services via REST.**
