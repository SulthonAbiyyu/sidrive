<div align="center">

<img src="assets/icons/logoapk.png" alt="SiDrive Logo" width="110"/>

# SiDrive
**Campus Ride & UMKM Delivery — Built for Students, by Students**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=flat-square&logo=supabase&logoColor=white)](https://supabase.com)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Midtrans](https://img.shields.io/badge/Midtrans-Payment-003399?style=flat-square)](https://midtrans.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-lightgrey?style=flat-square)]()
[![Demo](https://img.shields.io/badge/▶_Watch_Demo-FF0000?style=flat-square&logo=youtube&logoColor=white)](https://youtu.be/CztHOQvO2rU)

</div>

---

## What is SiDrive?

SiDrive is a **campus-exclusive mobility and commerce platform** — an all-in-one app where students can order rides, buy from fellow student vendors, and even earn income as a driver or shop owner.

What makes it different from Gojek or Grab? **The drivers are students themselves.** They know every corner of campus — which shortcut leads to Lab 3, where the back entrance to the library is, or which building the canteen is behind. You're not just getting a ride, you're getting a ride from someone who's been to the same classroom as you.

> Rides are limited to a **30 km radius** around campus and support **precise drop-pin to specific campus locations** — right down to a specific classroom, laboratory, or library floor. Something no commercial ride app can offer.

---

## Features

### For Students (Customer)

| | Feature | Description |
|---|---|---|
| 🪪 | **Student ID Verification** | Exclusive access via student ID scan or photo upload — no outsiders |
| 🎭 | **Triple Role** | One account, three roles: Customer, Driver, and UMKM owner — switch anytime |
| 🛵 | **Campus Ride** | Order motorcycle or car rides using an interactive OpenStreetMap |
| 📍 | **Precision Drop Pin** | Pin your exact location inside campus — specific classroom, lab, library, or canteen |
| 🛍️ | **UMKM Marketplace** | Browse, filter, and order from student-owned food and product vendors |
| 🔴 | **Live Tracking** | Watch your driver move in real-time on the map |
| 💬 | **In-App Chat** | Talk to your driver or seller directly during active orders |
| 💰 | **E-Wallet** | Top up and withdraw via Midtrans — QRIS, bank transfer, e-wallet |
| 🔔 | **Push Notifications** | Real-time order updates via Firebase FCM, even when the app is closed |
| ⭐ | **Ratings** | Rate your driver after every trip |
| 📜 | **Transaction History** | Full history of rides and UMKM purchases in one place |

### For Drivers

| | Feature | Description |
|---|---|---|
| 🟢 | **Online Toggle** | Go online or offline with one tap to start accepting orders |
| 📋 | **Order Management** | Accept or reject incoming orders with full route details |
| 🚗 | **Multi-Vehicle** | Register both motorcycle and car, switch active vehicle anytime |
| 📊 | **Earnings Dashboard** | Daily, weekly, and monthly income stats with visual charts |
| 💵 | **Cash Settlement** | Automated cash income settlement flow to platform admin |

### For UMKM Owners

| | Feature | Description |
|---|---|---|
| 📦 | **Product Management** | Add, edit, delete products with photos, stock, price, and category |
| 🧾 | **Real-time Orders** | Incoming orders with live status management |
| 🏬 | **Store Profile** | Customize store name, address, operating hours, and bank account |
| 💹 | **Revenue Reports** | Breakdown of sales, delivery fees, platform cut, and net income by period |

### For Admin (Web Dashboard)

| | Feature | Description |
|---|---|---|
| ✅ | **Verification Hub** | Review and approve/reject student ID, driver vehicles, and UMKM registrations |
| 👥 | **User Management** | Monitor all customers, drivers, and UMKM sellers with detail views |
| 💲 | **Pricing Control** | Configure ride fares, delivery fees, and platform commission percentage |
| 💸 | **Withdrawal Management** | Approve payout requests with proof of transfer upload |
| 💰 | **Financial Tracking** | Full cash flow monitoring across all services and payment methods |
| 🔄 | **Refund Management** | Process wallet refunds automatically, transfer refunds via Midtrans |
| 💬 | **Live Chat Support** | Real-time support chat with all users |

---

## Why It Works

### 🏫 Campus-Native Drivers
Drivers are fellow students — they have **physical access to restricted campus areas**, know internal building layouts by heart, and can deliver right to a specific room that standard ride-hailing apps simply can't reach.

### 🔐 Community-Locked Access
Every user is verified through their student ID before they can register. This creates a trusted, closed community where everyone is accountable to each other.

### 🛡️ Built-in Safety Layers

**Anti-Self Order** — Sellers can't order from their own store. Blocked automatically at the system level.

**Fraud-Proof Payments** — Payment status can only be updated by Midtrans' official server-side webhook using a Service Role key. No client-side manipulation is possible.

**Multi-Role Verification** — Each role (Driver, UMKM) requires separate document approval from admin before going live.

**Content Filtering** — Phone numbers in any format are automatically blocked inside chat to keep all communication on-platform.

**Auto-Cancel** — Orders with a driver GPS that hasn't moved for 10 minutes are automatically cancelled with a penalty deducted from the driver's balance.

---

## Tech Stack

```
Frontend          Flutter (Dart)
State Management  Provider
Backend           Supabase — PostgreSQL · Auth · Storage · Realtime
Serverless        Supabase Edge Functions (Deno / TypeScript)
Push Notification Firebase Cloud Messaging (FCM)
Maps              OpenStreetMap via flutter_map
Payment Gateway   Midtrans Snap & IRIS Payout
Responsive UI     flutter_screenutil
```

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  CLIENT LAYER                   │
│                                                 │
│   📱 Android App          🌐 Admin Web App      │
│   (Flutter - Client)      (Flutter - Web)       │
└──────────────────┬──────────────────┬───────────┘
                   │                  │
                   ▼                  ▼
┌─────────────────────────────────────────────────┐
│              SUPABASE BACKEND                   │
│                                                 │
│  PostgreSQL   Auth   Storage   Realtime   Edge  │
│  (Database)  (Login) (Files)  (WebSocket) Func  │
└──────────────────────────────┬──────────────────┘
                               │
                   ┌───────────┼───────────┐
                   ▼           ▼           ▼
              🔔 Firebase  💳 Midtrans  🗺️ OSM
                  FCM        Payments    Maps
```

---

## Project Structure

```
sidrive/
├── lib/
│   ├── main_client.dart               # Android app entry point
│   ├── main_admin.dart                # Web admin entry point
│   ├── app.dart                       # Root widget & all routes
│   ├── app_config.dart                # Flavor config (client / admin)
│   ├── config/
│   │   └── constants.dart             # App-wide constants & credentials
│   ├── core/
│   │   ├── theme/                     # Light & dark theme
│   │   └── widgets/                   # Shared reusable widgets
│   ├── providers/                     # Global state (Provider)
│   ├── services/                      # All business logic & API calls
│   └── screens/
│       ├── auth/                      # Login, register, verification
│       ├── customer/                  # Customer dashboard & ordering
│       ├── driver/                    # Driver dashboard & earnings
│       ├── umkm/                      # Store & product management
│       ├── admin/                     # Full admin web dashboard
│       ├── profile/                   # Shared profile screen
│       └── common/                    # Shared screens across roles
│
├── supabase/
│   └── functions/
│       ├── send-new-order-notification/    # Broadcast FCM to nearby drivers
│       ├── send-tracking-notification/     # Real-time status push updates
│       ├── create-midtrans-transaction/    # Payment token creation
│       ├── create-topup-transaction/       # Wallet top-up
│       ├── create-settlement-payment/      # Driver cash settlement
│       ├── check-payment-status/           # Payment status verification
│       ├── auto-cancel-order/              # Stuck GPS auto-cancel
│       ├── create-admin/                   # Admin account creation
│       ├── update-admin/                   # Admin account management
│       └── admin-payout/                   # Admin withdrawal via IRIS
│
├── assets/
│   ├── fonts/                         # Inter, Poppins, Montserrat
│   ├── icons/                         # App launcher icon
│   └── images/                        # Screen backgrounds & illustrations
│
└── pubspec.yaml
```

---

## Getting Started

### Prerequisites
- Flutter SDK 3.x+
- Android Studio or VS Code
- A Supabase project
- A Firebase project (for FCM)
- A Midtrans account

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/yourusername/sidrive.git
cd sidrive

# 2. Install dependencies
flutter pub get

# 3. Configure Supabase credentials
# Open lib/config/constants.dart
# Fill in your supabaseUrl and supabaseAnonKey

# 4. Add Firebase config
# Place google-services.json inside android/app/
# Place the Firebase Admin SDK JSON inside the project root
# (Request access to the config files via the link below)

# 5. Set Edge Function secrets in Supabase Dashboard
# Dashboard → Edge Functions → Secrets
# Required: MIDTRANS_SERVER_KEY · FIREBASE_PROJECT_ID · FIREBASE_SERVICE_ACCOUNT_KEY

# 6. Run
flutter run --flavor client -t lib/main_client.dart          # Android
flutter run --flavor admin -t lib/main_admin.dart -d chrome  # Web admin
```

### 🔑 Private Configuration Files

Firebase config files (`google-services.json`, Firebase Admin SDK key) and Supabase credentials (`supabaseUrl`, `supabaseAnonKey`, `service role key`) are **not included in this repository** for security reasons.

> **Request access here:** [Google Drive — Private Config Files](https://drive.google.com/drive/folders/1Ke_b5TIH3q5nPOU_N0utDL1wQQlzkLok?usp=sharing)
>
> Access is restricted. Click the link and request access — the owner will approve manually.

Once you have the files, place them as follows:
```
android/app/google-services.json
aplikasi-ojek-dan-umkm-umsida-firebase-adminsdk-xxxxx.json  ← project root
lib/config/constants.dart  ← fill in supabaseUrl & supabaseAnonKey
```

### Deploy Edge Functions

```bash
npm install -g supabase
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase functions deploy --all
```

### Build for Release

```bash
# Android APK
flutter build apk --flavor client -t lib/main_client.dart --release

# Admin Web
flutter build web --flavor admin -t lib/main_admin.dart
```

---

## What's Next

Features that would fit naturally into the campus context:

| | Idea | Why it makes sense |
|---|---|---|
| 🗺️ | **Custom Map Styles** | Replace default OSM tiles with styled themes (dark mode map, satellite view toggle) for a more polished feel |
| 🕐 | **Scheduled Rides** | Book a ride in advance — useful for early morning classes or exam days |
| 👥 | **Ride Sharing** | Split fare with friends heading to the same campus destination |
| 📣 | **Campus Announcements** | Push campus-wide info about events, road closures, or emergencies via the app |
| 🎟️ | **Promo & Voucher System** | Discount codes for loyal users or campus event promos |
| 📦 | **UMKM Product Return** | Structured return and refund flow for product orders |
| 📈 | **Driver Leaderboard** | Gamified rankings to reward top-performing drivers with campus perks |
| 🌐 | **PWA for Admin** | Install the admin dashboard as a Progressive Web App without needing a browser |
| 🔔 | **Order Sound Alerts** | Distinct alert sounds per order type so drivers notice new orders instantly |
| 📷 | **Delivery Photo Proof** | Drivers snap a photo at drop-off as proof of delivery for UMKM orders |

---

## License

This project is private. All rights reserved.

---

<div align="center">
Built with Flutter · Powered by Supabase · Notifications by Firebase
</div>