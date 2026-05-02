# ParaCodeCode Business App

## 📱 Business App Idea

ParaCodeCode Business App is a mobile application built with Flutter and Firebase that helps small businesses manage customer check-ins and process orders in one place. It allows staff to log customer arrivals and track order transactions efficiently, providing a simple and organized way to monitor daily business activity in real time.

---

## 🗄️ Firestore Collections

### 1. `Check-In Logs`
Tracks customer check-in activity and visit records.

| Field | Type | Description |
|---|---|---|
| `checkInId` | String | Unique ID for the check-in record |
| `customerName` | String | Full name of the customer |
| `contactNumber` | String | Customer's contact number |
| `checkInTime` | Timestamp | Date and time of check-in |
| `checkOutTime` | Timestamp | Date and time of check-out |
| `purpose` | String | Reason or purpose of visit |
| `status` | String | Current status (e.g., Checked In, Checked Out) |
| `notes` | String | Optional remarks from staff |

---

### 2. `Customer Orders`
Stores order details placed by customers.

| Field | Type | Description |
|---|---|---|
| `orderId` | String | Unique ID for the order |
| `customerName` | String | Name of the customer who placed the order |
| `contactNumber` | String | Customer's contact number |
| `orderItems` | Array | List of items ordered |
| `totalAmount` | Number | Total price of the order |
| `orderDate` | Timestamp | Date and time the order was placed |
| `paymentStatus` | String | Payment status (e.g., Paid, Pending, Cancelled) |
| `deliveryStatus` | String | Delivery/fulfillment status |
| `notes` | String | Special instructions or remarks |

---

## 🚀 Steps to Run

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/bsis3a-ParaCodeCode-businessapp.git
   cd bsis3a-ParaCodeCode-businessapp
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Go to [Firebase Console](https://console.firebase.google.com/) and create a project
   - Add your Android/iOS app and download the `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
   - Place the config file in the appropriate directory (`android/app/` or `ios/Runner/`)

4. **Run the app**
   ```bash
   flutter run
   ```

> **Requirements:** Flutter SDK 3.x+, Dart 3.x+, Android Studio or Xcode, Firebase project configured

---

## 📸 Screenshots

> _Screenshots will be added once the UI is finalized._

| Screen | Preview |
|---|---|
| Home / Dashboard | ![Home Screen](screenshots/home_screen.png) |
| Check-In Logs List | ![Check-In Logs](screenshots/checkin_logs.png) |
| Add Check-In Form | ![Add Check-In](screenshots/add_checkin.png) |
| Customer Orders List | ![Customer Orders](screenshots/customer_orders.png) |
| Add Order Form | ![Add Order](screenshots/add_order.png) |
| Order Details | ![Order Details](screenshots/order_details.png) |

---

## 👥 Team

**BSIS 3A — ParaCodeCode**

---
