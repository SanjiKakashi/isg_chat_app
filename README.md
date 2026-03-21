# ISG Chat App

A Flutter ChatGPT wrapper using Firebase, GetX, and SOLID principles. It includes authentication, chat functionality, and basic user session handling.
---

## ✅ Completed Features

- Guest Login
- Google Sign-In
- Apple Sign-In
- Chat Screen UI
- Conversation History (Drawer)
- Logout Functionality

---
## ⚠️ Known Limitations

- iOS testing not completed  
  (Reason: No access to MacBook or iPhone)

- Unit testing not implemented

- GPT model limited to **3.5**
    - Due to cost constraints
    - Current usage is restricted to a **$5 API limit**
    - Higher models (like GPT-4/5) were not used to avoid exceeding budget

---

## 🛠️ TODO / Improvements

- Edit message and regenerate response
- Retry / Stop generation actions
- Prompt suggestions or system prompts
- Dark mode support
- Responsive layout improvements

---

### Prerequisites

- Flutter SDK installed
- Android Studio / VS Code
- Xcode (for iOS - optional)

---

## Tech Stack

| | Package |
|---|---|
| State / Navigation | `get` |
| Auth | `firebase_auth`, `google_sign_in`, `sign_in_with_apple` |
| Database | `cloud_firestore` |
| AI | `http` (OpenAI SSE streaming) |
| Utilities | `uuid`, `crypto`, `logger` |

---

## State Management (GetX)

| Observable | Type | Purpose |
|------------|------|---------|
| `isLoading` | `RxBool` | Splash/login spinner |
| `currentUser` | `Rxn<UserProfile>` | Signed-in user |
| `messages` | `RxList<ChatMessage>` | Live message list |
| `conversations` | `RxList<Conversation>` | Drawer list |
| `conversationId` | `RxString` | Active conversation |
| `isGenerating` | `RxBool` | Disables input / toggles Send↔Cancel |

---

## Features

### Auth
- Google Sign-In (Android + iOS), Apple Sign-In (iOS only)
- Session checked once on cold start — routes to Chat or Login
- First login creates the user document. Returning login updates mutable fields only

### Chat
- Loads the most recent conversation on startup. Creates a new one only if none exist
- Message list is a **live Firestore snapshot stream** — UI updates automatically on every write

### OpenAI Streaming
1. User sends message → written to Firestore (`status: sent`)
2. AI placeholder written (`status: generating`) → typing indicator, input disabled, Send → Cancel
3. Each SSE token chunk written back to Firestore → bubble grows live
4. `[DONE]` → `status: done`, input re-enabled, Cancel → Send

### Chat History Drawer
- Lists all conversations sorted by most recent
- Tap a row → switches message stream to that conversation
- New conversation button and Sign-out at the top and bottom

---

## Error Handling

All errors return a typed `Failure` — nothing raw reaches the UI.

| Failure | When |
|---------|------|
| `AuthFailure` | Firebase Auth error |
| `FirestoreFailure` | Firestore write error (non-blocking) |
| `CancelledFailure` | User dismissed sign-in |
| `AiFailure(statusCode)` | OpenAI HTTP error |

`AiFailure` writes the message into the AI Firestore document so it appears directly in the chat bubble:

| Code | Message |
|------|---------|
| 429 | You've reached the request limit. Please wait a moment and try again. |
| 401 | Invalid API key. |
| 500–503 | OpenAI is temporarily unavailable. |

---

## Firestore Schema

```
users/{uid}
  ├── uid, displayName, email, photoUrl, provider
  ├── createdAt, lastLoginAt, isActive, totalConversations
  └── conversations/{conversationId}
        ├── uid, createdAt, lastMessageAt
        └── messages/{messageId}
              ├── ownerId      ← user uid  OR  "ai"
              ├── message, timestamp, createdAt
              └── status       ← sent | generating | done | cancelled
```

### Security Rules
```
match /users/{userId}/{document=**} {
  allow read, write: if request.auth.uid == userId;
}
```
