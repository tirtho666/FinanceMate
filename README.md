# FinanceMate 💰

A robust, full-stack personal finance and expense tracking application designed to help users manage their daily transactions with precision and security. Built with a scalable architecture, FinanceMate ensures seamless data synchronization and a smooth user experience.

## 🚀 Tech Stack

* **Frontend:** Flutter & Dart
* **Backend:** Node.js, Express.js
* **Database:** PostgreSQL (Hosted on Neon)
* **Hosting:** Render (Web Service)
* **State Management:** Provider
* **Version Control:** Git & GitHub

## 🏗️ Architecture

This project strictly follows **Clean Architecture** principles to separate concerns and maintain a highly scalable codebase:
* **Presentation Layer:** UI, Widgets, and State Management.
* **Domain Layer:** Business logic, Entities, and Core Use Cases.
* **Data Layer:** Repositories, Data Sources (Local & Remote API), and DTOs.

## ✨ Key Features

* **JWT Authentication:** Secure user sessions and API endpoint protection.
* **Local App Lock:** SHA-256 hashing via `flutter_secure_storage` for maximum device-level security.
* **Offline-First Synchronization:** Seamless offline data caching with automatic cloud database synchronization.
* **Comprehensive Expense Tracking:** Custom category filtering, multi-currency selection, and detailed transaction logging.
* **REST API Integration:** Non-blocking asynchronous execution ensuring fast communication between the Flutter app and Node.js server.