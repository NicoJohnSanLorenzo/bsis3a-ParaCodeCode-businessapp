# 📱 ParaCodeCode Business App: "MARKIFY"

A comprehensive Flutter-based business management application for inventory tracking, customer order management, and sales monitoring with real-time Firebase integration.

## 🚀 Features

### 📊 Dashboard
- Real-time overview of customer orders and inventory status
- Interactive scorecards showing total orders, processing, shipped, and delivered orders
- Low stock and out-of-stock alerts
- Beautiful pastel gradient UI design

### 👥 Customer Orders Management
- Create, read, update, and delete customer orders
- Categorize orders by status (Processing, Shipped, Delivered)
- Date picker for order creation
- Customer information tracking (name, address, phone number)
- Order details with product name and quantity
- Smooth animation on delete

### 📦 Inventory Management
- Track inventory items with stock status (In-stock, Low stock, Out-of-stock)
- Add product orders with proof label generation
- GPS location capture for inventory items
- Photo upload functionality (camera or gallery)
- Supplier information tracking
- Automatic proof label generation format: `GroupName-BusinessType-MMDD`

### 🎨 Design Features
- Pastel color palette for professional yet friendly UI
- Gradient backgrounds throughout the app
- Responsive card-based design
- Clean and intuitive navigation drawer
- Consistent styling across all screens

## 📱 Screens

1. **Dashboard Screen** - Main overview with metrics
2. **Customer Screen** - Manage customer orders
3. **Inventory Screen** - Track inventory items
4. **Add Customer Order Screen** - Create new orders
5. **Add Inventory Screen** - Create inventory entries

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **Backend:** Firebase Firestore
- **Authentication:** Firebase Auth (optional)
- **Location:** Geolocator package
- **Image Picker:** image_picker package
- **State Management:** StreamBuilder / StatefulWidget

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cloud_firestore: ^4.8.0
  geolocator: ^9.0.0
  image_picker: ^0.8.7

🏗️ Project Structure
lib/
├── screens/
│   ├── dashboard_screen.dart
│   ├── customer_screen.dart
│   ├── log_list_screen.dart (Inventory)
│   ├── add_customer_order_screen.dart
│   └── create_checkin_screen.dart (Add Inventory)
├── landing_screen.dart
└── main.dart

🚀 Getting Started
Prerequisites
- Flutter SDK (>=3.0.0)
- Dart (>=2.18.0)
- Firebase project
- Android Studio / VS Code

Installation
1. Clone the Respository
git clone https://github.com/yourusername/paracodecode-businessapp.git
cd paracodecode-businessapp

2. Install dependencies
flutter pub get

3. Configure Firebase
- Create a new Firebase project
- Add Android/iOS apps to Firebase
- Download google-services.json (Android) / GoogleService-Info.plist (iOS)
- Place files in the appropriate directories

4. Enable Firestore
- Go to Firebase Console → Firestore Database
- Create database in test mode (for development)

5. Run the app
flutter run

🔧 Firebase Collections Structure
customer_orders
{
  "customerName": "string",
  "customerAddress": "string",
  "phoneNumber": "string",
  "productName": "string",
  "orderQuantity": "number",
  "orderStatus": "string (Processing/Shipped/Delivered)",
  "dateCreated": "timestamp",
  "createdAt": "timestamp"
}

checkin_logs (Inventory)
{
  "proofLabel": "string (Group-Name-MMDD)",
  "groupName": "string",
  "businessType": "string",
  "productName": "string",
  "note": "string",
  "stockStatus": "string (In-stock/Low stock/Out-of-stock)",
  "supplierName": "string",
  "createdBy": "string",
  "createdAt": "timestamp",
  "lat": "number (optional)",
  "lng": "number (optional)",
  "hasPhoto": "boolean (optional)",
  "photoFileName": "string (optional)"
}

Color Palette
Color Name	Hex Code	Usage
Pastel Blue	#AEC6E8	Buttons, accents
Pastel Orange	#FFCBA4	Status badges
Deep Blue	#3A5A8A	App bars, primary buttons
Deep Orange	#D4845A	Processing status
In-stock Green	#5A8A6A	In-stock status
Low Stock Amber	#CB9A50	Low stock warning
Out-of-stock Red	#CC6666	Out-of-stock alerts

📱 Key Features Explained
Proof Label Generation
- Automatically generates unique proof labels
- Format: {GroupName}-{BusinessType}-{MMDD}
- Example: HMS-Hotel-0430 or ParaCode-Retail-0515
- Required field before saving inventory items

GPS Location Capture
- Fetch current device location
- Automatically attaches latitude/longitude to inventory items
- Useful for tracking product locations

Photo Management
- Take new photos using camera
- Select existing photos from gallery
- Preview before saving
- Remove photo option

🐛 Troubleshooting
Common Issues
1. "Failed to save: [cloud_firestore/invalid-argument]"
- Check field names match Firebase collection
- Verify data types (numbers vs strings)
- Ensure no fields exceed 1 MiB limit
2. Location not working
- Enable location permissions in device settings
- Check if location services are enabled
- Verify GPS/Location permission in app manifest
3. Images not saving
- Firestore has 1 MiB document limit
- Consider using Firebase Storage for images
- Reduce image quality before upload
