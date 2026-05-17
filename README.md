# 🏪 Markify — Business Management App

> **BSIS 3A — ParaCodeCode** | Flutter + Firebase + Groq AI

---

## 📱 App Overview

**Markify** is a mobile business management app built with Flutter and Firebase. It helps small businesses track inventory, manage customer orders, and get real-time AI-powered insights — all from a role-aware, clean interface.

---

## ⬇️ Download the APK

[![Download APK](https://img.shields.io/badge/Download-Markify%20v1.0.1-blue?style=for-the-badge&logo=android)](https://github.com/NicoJohnSanLorenzo/bsis3a-ParaCodeCode-businessapp/releases/tag/v1.0.1)

> **Requires:** Android 6.0 (API 23) or higher

---

## 🤖 AI Feature Showcase — Step by Step

The AI Assistant is the main highlight of the app. Here's exactly how to run and demonstrate it:

### Prerequisites

Before launching the app, make sure you have a **Groq API key** (free at [console.groq.com](https://console.groq.com)):

1. Create a `.env` file in the root of the project
2. Add the following line:
   ```
   GROQ_API_KEY=your_groq_api_key_here
   ```

---

### 🚀 Step-by-Step: Showcasing the AI

#### Step 1 — Register or Log In
- Launch the app → tap **Register** to create a new account, or **Login** with existing credentials
- Use any valid email and password (Firebase Auth)

#### Step 2 — Seed Some Data (Important for AI context)
Before using the AI, add real data so it has something to analyze:

- Go to **Customer Orders** → tap the **＋** button → add at least 2–3 orders with different statuses (`Processing`, `Shipped`, `Delivered`)
- Go to **Inventory (Log List)** → tap **＋** → add items with statuses like `Low stock` or `Out-of-stock`

#### Step 3 — Open the AI Assistant
- From the Dashboard, tap the **AI Assistant** icon (sparkle ✨ icon in the bottom nav)
- The assistant greets you and shows **5 quick-tap suggestion chips**

#### Step 4 — Try These Suggested Questions (tap the chips or type manually)

| Question | What the AI Does |
|---|---|
| `How many orders are processing?` | Pulls live Firestore order data and counts by status |
| `Which products are low in stock?` | Lists all inventory items marked Low/Out-of-stock |
| `Give me a business summary` | Generates a full summary of orders + inventory |
| `How many customers do we have?` | Counts records from the customers collection |
| `Any out-of-stock products?` | Highlights critical stock alerts |

#### Step 5 — Ask Custom Questions
Type anything in the input bar, for example:
- *"Which orders haven't been delivered yet?"*
- *"What's the total number of inventory items?"*
- *"Summarize today's business status"*

The AI fetches **live data from Firestore** on every message, so answers always reflect the current state of your business.

---

## 🧠 How the AI Works (Technical)

```
User Question
     │
     ▼
Fetch live data from Firestore
  ├── customer_orders (all records)
  ├── checkin_logs    (inventory)
  └── customers       (customer list)
     │
     ▼
Build structured context string
  (order counts by status, low/out-of-stock items, recent order details)
     │
     ▼
Send to Groq API — llama-3.1-8b-instant model
  System prompt: business assistant persona + live data context
  User message: the question
     │
     ▼
Display AI response in chat bubble
```

**Model used:** `llama-3.1-8b-instant` via Groq Cloud (free tier, very fast)  
**API key:** loaded from `.env` file at runtime — never hardcoded  
**Max tokens:** 512 per response

---

## ✨ All App Features

| Feature | Description |
|---|---|
| 🔐 Authentication | Email/password login & registration via Firebase Auth |
| 📊 Dashboard | Real-time overview of order statuses and stock alerts |
| 🛒 Customer Orders | View, search, filter, and add orders |
| 📦 Inventory | Track stock levels with Low Stock / Out-of-Stock alerts |
| 🤖 AI Assistant | Chat-based assistant powered by **Groq (LLaMA 3.1)** with live Firestore context |
| 👥 User Management | Admin-only screen to assign and change user roles (Admin / Staff) |
| 🔔 Notifications | Bell icon with live badge count for stock alerts |

---

## 🗄️ Firestore Collections

### `customer_orders`
| Field | Type | Description |
|---|---|---|
| `customerName` | String | Name of the customer |
| `address` | String | Delivery address |
| `phone` | String | Contact number |
| `product` | String | Product ordered |
| `quantity` | Number | Quantity ordered |
| `orderStatus` | String | `Processing`, `Shipped`, or `Delivered` |
| `dateCreated` | Timestamp | Date and time placed |

### `checkin_logs` (Inventory)
| Field | Type | Description |
|---|---|---|
| `productName` | String | Name of the product |
| `stockStatus` | String | `In-stock`, `Low stock`, or `Out-of-stock` |
| `supplierName` | String | Supplier name |
| `note` | String | Optional staff notes |
| `createdBy` | String | Staff who logged the item |
| `imageUrl` | String | Optional photo proof URL |
| `createdAt` | Timestamp | Record creation date |

### `users`
| Field | Type | Description |
|---|---|---|
| `email` | String | User's email |
| `role` | String | `admin` or `staff` |
| `createdAt` | Timestamp | Account creation date |

---

## 🛠️ Running from Source

### Requirements
- Flutter SDK 3.x+
- Dart 3.x+
- Android Studio / Xcode
- Firebase project (Android + iOS configured)
- Groq API key ([console.groq.com](https://console.groq.com) — free)

### Steps

```bash
# 1. Clone the repo
git clone https://github.com/NicoJohnSanLorenzo/bsis3a-ParaCodeCode-businessapp.git
cd bsis3a-ParaCodeCode-businessapp

# 2. Install dependencies
flutter pub get

# 3. Set up Firebase
#    - Place google-services.json in android/app/
#    - Place GoogleService-Info.plist in ios/Runner/

# 4. Create .env file in project root
echo "GROQ_API_KEY=your_groq_api_key_here" > .env

# 5. Run the app
flutter run
```

---

## 📦 Key Dependencies

| Package | Purpose |
|---|---|
| `firebase_core` | Firebase initialization |
| `firebase_auth` | User authentication |
| `cloud_firestore` | Realtime database |
| `flutter_dotenv` | `.env` file for API key management |
| `http` | Groq AI API HTTP calls |
| `geolocator` | GPS coordinates for inventory logs |
| `image_picker` | Camera/gallery photo upload |

---

## 👥 Team

**BSIS 3A — ParaCodeCode**

---

*© 2026 Markify. All rights reserved.*
