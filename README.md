# Markify — ParaCodeCode Business App

## 📱 About the App

**Markify** is a mobile application built with Flutter and Firebase that helps small businesses manage inventory and customer orders in one place. Staff can log and track inventory stock levels, manage customer orders, and receive real-time stock alerts — all from a clean, role-aware interface. Admins get additional controls to manage user roles and permissions across the team.

---

## 📥 Download

[![Download APK](https://img.shields.io/badge/Download-Markify%20v1.0.0-blue?style=for-the-badge&logo=android)](https://github.com/NicoJohnSanLorenzo/bsis3a-ParaCodeCode-businessapp/releases/tag/v1.0.0)

> Requires Android 6.0 or higher

---

## ✨ Features

| Feature | Description |
|---|---|
| 🔐 Authentication | Email/password login and registration via Firebase Auth |
| 📊 Dashboard | Real-time overview of order statuses and inventory alerts |
| 🛒 Customer Orders | View, search, filter, and add customer orders |
| 📦 Inventory | Track product stock levels with Low Stock / Out-of-Stock alerts |
| 🤖 AI Assistant | Chat-based assistant (powered by Groq API) for business queries |
| 👥 User Management | Admin-only screen to assign and change user roles |
| 🔔 Notifications | Bell icon with live badge count for stock alert items |

---

## 🗂️ App Screens

| Screen | File |
|---|---|
| Landing (Welcome) | `landing_screen.dart` |
| Login | `login_screen.dart` |
| Register | `register_screen.dart` |
| Dashboard | `dashboard_screen.dart` |
| Customer Orders | `customer_screen.dart` |
| Add Customer Order | `add_customer_order_screen.dart` |
| Inventory (Log List) | `log_list_screen.dart` |
| Add Inventory Item | `create_checkin_screen.dart` |
| AI Assistant | `ai_assistant_screen.dart` |
| Manage Users (Admin) | `admin_users_screen.dart` |

---

## 🗄️ Firestore Collections

### 1. `customer_orders`
Stores order details placed by customers.

| Field | Type | Description |
|---|---|---|
| `customerName` | String | Name of the customer |
| `address` | String | Delivery address |
| `phone` | String | Contact number |
| `product` | String | Product ordered |
| `quantity` | Number | Quantity ordered |
| `orderStatus` | String | `Processing`, `Shipped`, or `Delivered` |
| `dateCreated` | Timestamp | Date and time the order was placed |

---

### 2. `checkin_logs`
Tracks inventory items and their stock levels.

| Field | Type | Description |
|---|---|---|
| `productName` | String | Name of the product |
| `stockStatus` | String | `In-stock`, `Low stock`, or `Out-of-stock` |
| `supplierName` | String | Name of the supplier |
| `note` | String | Optional staff notes |
| `createdBy` | String | Staff member who logged the item |
| `groupName` | String | Product group or brand label |
| `businessType` | String | Type of business/category |
| `latitude` | Number | GPS latitude at time of log |
| `longitude` | Number | GPS longitude at time of log |
| `imageUrl` | String | Optional proof/photo URL |
| `createdAt` | Timestamp | Date and time the record was created |

---

### 3. `users`
Stores user profile and role information.

| Field | Type | Description |
|---|---|---|
| `email` | String | User's email address |
| `role` | String | `admin` or `staff` |
| `createdAt` | Timestamp | Account creation date |

---

## 🚀 Steps to Run

1. **Clone the repository**
```bash
   git clone https://github.com/NicoJohnSanLorenzo/bsis3a-ParaCodeCode-businessapp.git
   cd bsis3a-ParaCodeCode-businessapp
```

2. **Install Flutter dependencies**
```bash
   flutter pub get
```

3. **Set up Firebase**
   - Go to [Firebase Console](https://console.firebase.google.com/) and create a project
   - Add your Android/iOS app and download `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
   - Place the config file in the appropriate directory (`android/app/` or `ios/Runner/`)

4. **Configure your API key**
   - Create a `.env` file in the project root
   - Add your Groq API key:
```bash
   GROQ_API_KEY=your_groq_api_key_here
```

5. **Run the app**
```bash
   flutter run
```

> **Requirements:** Flutter SDK 3.x+, Dart 3.x+, Android Studio or Xcode, Firebase project configured

---

## 📦 Key Dependencies

| Package | Purpose |
|---|---|
| `firebase_core` | Firebase initialization |
| `firebase_auth` | User authentication |
| `cloud_firestore` | Realtime database |
| `flutter_dotenv` | Environment variable management |
| `http` | Groq AI API calls |
| `geolocator` | GPS coordinates for inventory logs |
| `image_picker` | Camera/gallery photo upload |

---

## 👥 Team

**BSIS 3A — ParaCodeCode**

