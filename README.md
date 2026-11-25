# FinanceMate

A personal finance and expense tracking mobile app built with Flutter, backed by a custom Node.js and PostgreSQL REST API. The app is designed around Clean Architecture and an offline-first workflow so transactions can be recorded, filtered, and managed reliably even without an active internet connection.

- **Backend Repository:** [github.com/tirtho666/FinanceMate-Backend](https://github.com/tirtho666/FinanceMate-Backend)
- **Live API Base URL:** `[https://financemate-backend.onrender.com](https://financemate-backend.onrender.com)`
  
<img width="590" height="1280" alt="WhatsApp Image 2026-11-25 at 1 47 13 PM (2)" src="https://github.com/user-attachments/assets/4bf29247-c947-447e-a9f1-064ab45fae0f" />
<img width="590" height="1280" alt="WhatsApp Image 2026-11-25 at 1 47 11 PM (1)" src="https://github.com/user-attachments/assets/9a6a8b8f-9a4a-448d-88ae-8d13b5661dfc" />
<img width="590" height="1280" alt="WhatsApp Image 2026-11-25 at 1 47 11 PM" src="https://github.com/user-attachments/assets/bc0850ed-4a6b-4189-980b-0ef0232c6741" />
<img width="590" height="1280" alt="WhatsApp Image 2026-11-25 at 1 47 08 PM (1)" src="https://github.com/user-attachments/assets/38300f31-bd1a-44fc-8778-38550696dd28" />
<img width="590" height="1280" alt="WhatsApp Image 2026-11-25 at 1 47 14 PM" src="https://github.com/user-attachments/assets/518a3b3a-a03d-47de-955a-39a8a23530b6" />

## Tech Stack

**Mobile App (Frontend)**
- **Framework:** Flutter & Dart
- **State Management:** Provider
- **Local Database & Storage:** `sqflite` (offline transaction queue & cache), `shared_preferences`
- **Security:** `flutter_secure_storage` & `crypto` (local SHA-256 password hashing)
- **Networking:** `http`

**Backend & Database**
- **Runtime & Framework:** Node.js & Express.js
- **Database:** PostgreSQL (hosted on Neon)
- **Authentication:** JWT (30-day expiry) & `bcrypt`
- **Hosting:** Render

## Project Architecture

The codebase is organized into three separate layers following Clean Architecture:

- **Presentation:** UI screens, reusable widgets, custom category grids, and Provider classes for reactive state updates.
- **Domain:** Core entities (`FinanceTransaction`, `UserProfile`, `TransactionSummary`), repository contracts, and failure handling.
- **Data:** Remote API data sources, local SQLite storage (`sqflite`), and repository implementations handling offline queuing and background synchronization.

## Features

- **Offline-First Transaction Engine:** Add or delete transactions offline using local SQLite storage. Queued records sync automatically with PostgreSQL once connectivity is restored.
- **Instant UI & Live Summary:** Optimistic deletion and real-time recalculation immediately update Current Balance, Total Income, and Total Expense across the dashboard.
- **Filtering & History:** Filter transactions by timeframe (`All`, `This Month`, `Last Month`) and specific categories.
- **Dual-Layer Security:** Cloud API routes are secured with JWT Bearer tokens, while an optional device-level App Lock verifies a locally stored SHA-256 password hash on launch.
- **Multi-Currency Support:** Persistent currency formatting saved locally via `shared_preferences`.

## API Endpoints

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/auth/signup` | Register a new user account |
| `POST` | `/api/auth/login` | Authenticate user and issue a 30-day JWT |
| `GET` | `/api/users/profile` | Fetch authenticated user profile |
| `PATCH` | `/api/users/profile` | Update user profile details |
| `POST` | `/api/users/change-password` | Update account password and sync local App Lock |
| `POST` | `/api/transactions` | Create a new income or expense record |
| `GET` | `/api/transactions` | Fetch transactions (supports date range & category filters) |
| `PUT` | `/api/transactions/:id` | Update an existing transaction |
| `DELETE` | `/api/transactions/:id` | Delete a transaction |
| `GET` | `/api/transactions/summary` | Retrieve overall balance, income, and expense totals |

## Development Progress

- [x] **Phase 0:** Core Flutter UI/UX, Custom Category Grid & Initial Prototype
- [x] **Phase 1:** Node.js + Express REST API & Neon PostgreSQL Schema Setup
- [x] **Phase 2:** Backend Deployment on Render
- [x] **Phase 3:** Full Migration from Firebase to Custom REST API
- [x] **Phase 4:** SQLite Offline Sync, Optimistic Delete & SHA-256 App Lock

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/tirtho666/FinanceMate.git
   cd FinanceMate
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```
   *(The app connects directly to `https://financemate-backend.onrender.com` out of the box.)*
