# FinanceMate 💰

A full-stack personal finance and expense tracking mobile application built with Flutter. Designed with a strict Clean Architecture and an Offline-First approach, FinanceMate provides real-time financial tracking, multi-currency support, and enterprise-grade dual security.

## 🚀 Tech Stack

### Mobile Client (Frontend)
* **Framework:** Flutter & Dart
* **State Management:** Provider
* **Offline Caching & Local Storage:** `sqflite` & `shared_preferences`
* **Security:** `flutter_secure_storage` & `crypto` (SHA-256 local hashing)
* **Networking:** `http` (REST API integration)

### Server & Database (Backend)
* **Runtime & Framework:** Node.js & Express.js (Clean Architecture)
* **Database:** PostgreSQL (Hosted on Neon)
* **Authentication:** JWT (30-day expiry) & `bcrypt` (10 salt rounds)
* **Deployment:** Render (Web Service)

## 🏗️ Architecture

This project strictly follows **Clean Architecture** principles to separate concerns and maintain a scalable codebase:
* **Presentation Layer:** Flutter UI screens, custom widgets, and Provider state management.
* **Domain Layer:** Core business logic, financial summary calculations, and use cases.
* **Data Layer:** Repository pattern managing remote REST API calls and local SQLite caching with automatic background sync.

## ✨ Key Features

* **Dual-Layer Security & App Lock:** 
  * Cloud endpoints protected via JWT Bearer tokens.
  * Device-level **App Lock** powered by synchronous SHA-256 password hashing stored in `flutter_secure_storage`, verified locally in RAM on app launch.
  * Automatic local App Lock sync whenever the cloud password is updated.
* **Offline-First Transaction Engine:** 
  * Record income and expenses without internet using `sqflite`.
  * Automatic background sync (`POST`) to PostgreSQL when internet connectivity returns.
* **Dynamic Financial Overview:** 
  * Real-time calculation of Current Balance, Total Income, and Total Expense.
  * Filter transactions by timeframe (`This Month`, `Last Month`) and custom categories.
* **Multi-Currency Support:** Persistent global currency selection saved via `shared_preferences`.

## 🔌 REST API Endpoints

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/auth/signup` | Register a new user account |
| `POST` | `/api/auth/login` | Authenticate user & issue 30-day JWT |
| `GET` | `/api/users/profile` | Retrieve authenticated user profile |
| `PUT` | `/api/users/profile` | Update user details (Name, Phone, Photo) |
| `PUT` | `/api/users/change-password` | Update password & sync local App Lock |
| `POST` | `/api/transactions` | Add a new income or expense record |
| `GET` | `/api/transactions` | Fetch transactions (`?month=`, `?category=`) |
| `GET` | `/api/transactions/summary` | Get Current Balance, Total Income & Expense |

## 🗺️ Development Roadmap

* [x] **Phase 0:** Core Flutter UI/UX & Initial Prototype
* [ ] **Phase 1:** Node.js + Express Backend & Neon PostgreSQL Setup
* [ ] **Phase 2:** REST API Deployment on Render Web Service
* [ ] **Phase 3:** Flutter Migration (Firebase Removal & REST API Integration)
* [ ] **Phase 4:** Dual Security App Lock & SQLite Offline Sync

## ⚙️ Local Setup

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/tirtho666/FinanceMate.git](https://github.com/tirtho666/FinanceMate.git)
   cd FinanceMate
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Configure API URL:**
   Add your live Render backend URL in the API configuration file.
4. **Run the app:**
   ```bash
   flutter run
   ```
