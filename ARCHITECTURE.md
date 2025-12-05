# Clinic/Salon Booking Platform - System Architecture

## 1. High-Level Design (HLD)

### 1.1 System Overview

System: **Clinic/Salon Booking Platform**

Goal: Allow **customers** to book appointments with **clinics/salons (admins)**.

Platforms:
* Web (Flutter Web)
* Mobile (Flutter Android, later iOS)

Architecture style: **Client–Server (REST APIs)**

### Main Components

1. **Frontend (Flutter app)**
   * Runs on web & mobile
   * Implements UI for:
     * Customers (browse, book, manage bookings)
     * Admins (manage clinic, services, bookings, stats)
   * Communicates with backend via REST/HTTP + JSON.

2. **Backend (Node.js + Express)**
   * Exposes REST API endpoints.
   * Handles:
     * Authentication & authorization (JWT)
     * CRUD on clinics, services, bookings
     * Slot generation logic
     * Admin stats
   * Talks to MongoDB.

3. **Database (MongoDB)**
   * Stores:
     * `users`
     * `clinics`
     * `services`
     * `bookings`

4. **Optional External Services (future)**
   * Email/SMS/WhatsApp for reminders & notifications.

---

### 1.2 System Context

**Actors:**

* **Customer**
  * Registers, logs in
  * Views clinic info & services
  * Checks available slots
  * Books/cancels appointments
  * Views booking history

* **Admin (Clinic/Salon Owner)**
  * Registers as admin, logs in
  * Creates & manages clinic
  * Creates & manages services
  * Views bookings and stats
  * Updates booking statuses

**External Systems:**
* MongoDB instance
* (Optional) Notification services

**Data Flow (very high level):**
* Frontend ⇄ Backend (JSON over HTTP)
* Backend ⇄ MongoDB (Mongoose calls)

---

### 1.3 Deployment View

* **Backend:**
  * Node.js app (Express)
  * Runs on a server (e.g. Render, Railway, VPS, etc.)
  * Exposes REST endpoints (port e.g. 5000)

* **Database:**
  * Hosted MongoDB (e.g. MongoDB Atlas)

* **Frontend:**
  * Flutter Web → compiled to static files served via hosting (e.g. Netlify, Vercel, or same Node server).
  * Flutter Android → APK/AAB shipped to devices.

---

### 1.4 Major Features

* User registration & login (JWT-based)
* Role-based access control (`customer`, `admin`)
* Single-clinic management per admin (MVP)
* Service management per clinic
* Automatic appointment slot generation
* Booking with overlapping protection
* Booking lifecycle: `pending` → `confirmed` → `completed` / `cancelled`
* Admin stats & dashboard

---

## 2. Low-Level Design (LLD) – Backend

### 2.1 Backend Tech Stack

* Node.js
* Express
* MongoDB + Mongoose
* JSON Web Tokens (JWT)
* bcrypt for password hashing
* dotenv, cors, etc.

---

### 2.2 Backend Folder Structure

```
backend/
  src/
    config/
      db.ts
    models/
      User.ts
      Clinic.ts
      Service.ts
      Booking.ts
    middleware/
      auth.ts        // JWT auth
      isAdmin.ts     // admin role check
      ownerGuard.ts  // ensure admin owns a clinic/resource
    controllers/
      auth.controller.ts
      clinic.controller.ts
      service.controller.ts
      booking.controller.ts
      admin.controller.ts
    routes/
      auth.routes.ts
      clinic.routes.ts
      service.routes.ts
      booking.routes.ts
      admin.routes.ts
    utils/
      timeUtils.ts   // slot generation and time parsing
      errorHandler.ts
    index.ts         // Express app bootstrap
```

---

### 2.3 Data Models (Mongoose Schemas)

### User

```ts
User {
  _id: ObjectId;
  name: string;
  email: string;            // unique
  passwordHash: string;
  phone?: string;
  role: 'customer' | 'admin';
  createdAt: Date;
  updatedAt: Date;
}
```

### Clinic

```ts
Clinic {
  _id: ObjectId;
  owner: ObjectId;          // ref User (admin)
  name: string;
  type: 'clinic' | 'salon';
  address: string;
  city: string;
  description?: string;
  logoUrl?: string;
  coverImageUrl?: string;
  openingTime: string;      // "HH:MM"
  closingTime: string;     // "HH:MM"
  slotDurationMinutes: number; // e.g. 30
  createdAt: Date;
  updatedAt: Date;
}
```

### Service

```ts
Service {
  _id: ObjectId;
  clinic: ObjectId;         // ref Clinic
  name: string;
  description?: string;
  price: number;
  durationMinutes: number;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}
```

### Booking

```ts
Booking {
  _id: ObjectId;
  clinic: ObjectId;         // ref Clinic
  customer: ObjectId;       // ref User
  service: ObjectId;        // ref Service
  date: string;             // "YYYY-MM-DD"
  startTime: string;        // "HH:MM"
  endTime: string;          // "HH:MM"
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled';
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}
```

---

### 2.4 Key Backend Modules & Responsibilities

### 2.4.1 Auth Controller

**Functions:**

* `register(req, res)`
  * Validate request body.
  * Check if email exists.
  * Hash password.
  * Create `User` with role.
  * Return userId.

* `login(req, res)`
  * Validate body.
  * Find user by email.
  * Compare password using bcrypt.
  * Generate JWT with `{ userId, role }`.
  * Return token + user info.

### 2.4.2 Auth Middleware (`auth.ts`)

* Reads `Authorization` header (`Bearer <token>`).
* Verifies token.
* On success, attaches `req.user = { userId, role }`.
* On failure, returns 401.

### 2.4.3 isAdmin Middleware

* Ensures `req.user.role === 'admin'`.
* Otherwise returns 403.

### 2.4.4 ownerGuard Middleware (optional)

* Checks that current admin owns resource (clinic / service / booking's clinic).
* For example, when updating clinic:
  * Fetch clinic by `:id`.
  * Ensure `clinic.owner.toString() === req.user.userId`.

---

### 2.4.5 Clinic Controller

* `createClinic(req, res)`
  * Allowed only for admins.
  * Creates `Clinic` with `owner = req.user.userId`.

* `getClinicById(req, res)`
  * Public.
  * Returns clinic details (no owner id exposed if not needed).

* `updateClinic(req, res)`
  * Admin-only.
  * Uses `ownerGuard` to ensure this admin owns the clinic.
  * Updates fields.

---

### 2.4.6 Service Controller

* `getServicesForClinic(req, res)`
  * Public.
  * Returns active services for a clinic.

* `createService(req, res)`
  * Admin-only.
  * Checks that clinic belongs to this admin.
  * Creates service.

* `updateService(req, res)`
  * Admin-only, owner only.

* `deleteService(req, res)`
  * Admin-only, owner only.

---

### 2.4.7 Booking Controller

* `getAvailableSlots(req, res)`
  * Public.
  * Inputs: `clinicId`, `date` query.
  * Steps (LLD-style pseudocode):
    ```
    1. Read clinic by clinicId.
    2. Parse clinic.openingTime, closingTime to minutes.
    3. Create array of time slots:
       - for t = openingMinutes to closingMinutes - duration step duration:
         - push HH:MM string into allSlots.
    4. Query bookings:
       - where clinic == clinicId
       - and date == query.date
       - and status != 'cancelled'
    5. Extract booked startTime values into array.
    6. Filter allSlots to remove booked startTime values.
    7. Return { date, slots: filteredSlots }.
    ```

* `createBooking(req, res)`
  * Customer-only.
  * Body: `clinicId`, `serviceId`, `date`, `startTime`, (optional `endTime`, `notes`).
  * Steps:
    ```
    1. Verify clinic and service exist and belong.
    2. Compute endTime from service.durationMinutes if not provided.
    3. Check for existing booking at same clinic + date + startTime (not cancelled).
    4. If conflict → 400 error.
    5. Create booking with:
       - clinic, service, customer = req.user.userId
       - date, startTime, endTime
       - status = 'pending'
    6. Return booking.
    ```

* `getMyBookings(req, res)`
  * Customer-only.
  * Find bookings where `customer = req.user.userId`.

* `cancelBooking(req, res)`
  * Customer or Admin.
  * If customer:
    * Ensure booking.customer == req.user.userId.
  * If admin:
    * Ensure booking.clinic.owner == req.user.userId.
  * Ensure `status != 'completed'`.
  * Set `status = 'cancelled'`.

* `updateBookingStatus(req, res)` (admin)
  * Only for bookings in admin's clinic.
  * Update `status` to one of allowed values.

---

### 2.4.8 Admin Controller

* `getTodayBookings(req, res)`
  * Admin-only.
  * Query by `clinicId` (owned by admin) and `date = today`.

* `getStats(req, res)`
  * Admin-only.
  * For the given clinic:
    * `totalBookings`
    * `todayBookings`
    * `completedBookings`

---

### 2.5 Utilities

### timeUtils.ts

* `timeStringToMinutes("HH:MM") -> number`
* `minutesToTimeString(number) -> "HH:MM"`
* `generateSlots(openingTime, closingTime, slotDurationMinutes) -> string[]`

---

## 3. Low-Level Design (LLD) – Frontend (Flutter)

### 3.1 Flutter Architecture

* State management: `provider` or `riverpod` (any is fine, spec is generic).
* API communication: `http` package.
* Central `ApiClient` handling:
  * Base URL
  * Attaching `Authorization` header when token exists.
* Auth state stored in:
  * `AuthStore` (holds `user`, `token`, `role`).

---

### 3.2 Flutter Folder Structure

```
lib/
  main.dart
  core/
    api_client.dart     // handles GET/POST etc.
    auth_store.dart     // ChangeNotifier/Provider for auth state
    app_routes.dart     // named routes
    app_theme.dart      // colors, text styles
  models/
    user.dart
    clinic.dart
    service.dart
    booking.dart
  screens/
    auth/
      login_screen.dart
      register_screen.dart
    customer/
      clinic_booking_page.dart
      my_bookings_page.dart
    admin/
      admin_dashboard_page.dart
      manage_clinic_page.dart
      manage_services_page.dart
      admin_bookings_page.dart
  widgets/
    primary_button.dart
    text_input_field.dart
    service_chip.dart
    booking_card.dart
```

---

### 3.3 Frontend Data Models (Dart)

Simple DTO-style classes matching backend JSON.

Example `Booking`:

```dart
class Booking {
  final String id;
  final Clinic clinic;
  final Service service;
  final DateTime date;      // or store as string
  final String startTime;   // "HH:MM"
  final String endTime;
  final String status;

  Booking({
    required this.id,
    required this.clinic,
    required this.service,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'],
      clinic: Clinic.fromJson(json['clinic']),    // maybe populated or partial
      service: Service.fromJson(json['service']),
      date: DateTime.parse(json['date']),         // if stored as ISO; or keep string
      startTime: json['startTime'],
      endTime: json['endTime'],
      status: json['status'],
    );
  }
}
```

(Similar for `User`, `Clinic`, `Service`.)

---

### 3.4 Navigation Flow

### Unauthenticated state

* Entry:
  * `LoginScreen`
  * Button/link → `RegisterScreen`
* After successful login:
  * If `role == 'customer'` → `ClinicBookingPage`
  * If `role == 'admin'` → `AdminDashboardPage`

### Customer screens

* `ClinicBookingPage`:
  * Shows clinic details, services, booking form.
  * On "My bookings" button → `MyBookingsPage`.

* `MyBookingsPage`:
  * Lists bookings from `/api/bookings/my`.
  * Cancel button → calls `/api/bookings/:id/cancel`.

### Admin screens

* `AdminDashboardPage`:
  * Calls `/api/admin/stats` and `/api/admin/bookings/today`.
  * Buttons:
    * "Manage clinic" → `ManageClinicPage`
    * "Manage services" → `ManageServicesPage`
    * "All bookings" → `AdminBookingsPage`

* `ManageClinicPage`:
  * Form bound to `/api/clinic/:id` (GET + PUT).

* `ManageServicesPage`:
  * Fetches `/api/clinic/:clinicId/services`.
  * Add/edit/delete services via service routes.

* `AdminBookingsPage`:
  * Calls endpoint (e.g. `/api/admin/bookings/all?clinicId=...` or reuse today endpoint with filter).
  * Change booking status via `/api/bookings/:id/status`.

---

### 3.5 UI / UX Guidelines

* Global theme: dark background, gradient accent.
* Use cards with large border-radius (16–24) and subtle shadows.
* On web:
  * Center content up to `maxWidth ~900–1100`.
  * Use 2-column layout for booking page (clinic info left, booking widget right).
* On mobile:
  * Stack vertically, scrollable.

---

## 4. Sequence / Flow Diagrams (Text Form)

### 4.1 Login Flow (Customer/Admin)

1. User enters email + password → taps "Login".
2. Flutter → `POST /api/auth/login`.
3. Backend:
   * Validate.
   * Generate JWT.
   * Respond with `{ token, user }`.
4. Flutter:
   * Saves token.
   * If `user.role == 'customer'` → navigate to `ClinicBookingPage`.
   * If `user.role == 'admin'` → navigate to `AdminDashboardPage`.

---

### 4.2 Booking Flow (Customer)

1. Customer opens `ClinicBookingPage`.
2. Flutter:
   * `GET /api/clinic/:id`
   * `GET /api/clinic/:id/services`
3. Customer selects:
   * Service
   * Date
4. Customer taps "Check slots".
5. Flutter → `GET /api/bookings/slots?clinicId=&date=`.
6. Backend:
   * Generates slot list.
   * Filters out booked slots.
   * Returns free slots.
7. Customer picks a slot and taps "Confirm booking".
8. Flutter → `POST /api/bookings` with token.
9. Backend:
   * Validates, checks slot not taken.
   * Creates booking with status `pending`.
   * Returns booking.
10. Flutter shows confirmation and optionally navigates to `MyBookingsPage`.

---

### 4.3 Admin: View Today's Bookings

1. Admin opens `AdminDashboardPage`.
2. Flutter →
   * `GET /api/admin/stats?clinicId=...`
   * `GET /api/admin/bookings/today?clinicId=...`
3. Backend:
   * Verifies token and role.
   * Ensures clinic belongs to admin.
   * Returns stats and list.
4. Admin sees list and can click a booking to change status.

---

### 4.4 Booking Status Update (Admin)

1. Admin selects booking in dashboard.
2. Chooses new status (e.g. `confirmed`).
3. Flutter → `PATCH /api/bookings/:id/status` with `{ status: "confirmed" }`.
4. Backend:
   * Verifies admin owns the clinic of this booking.
   * Updates status.
5. Flutter updates UI.

---

### 4.5 Booking Cancellation (Customer)

1. Customer opens `MyBookingsPage`.
2. Flutter → `GET /api/bookings/my`.
3. Customer taps "Cancel" on future booking.
4. Flutter → `PATCH /api/bookings/:id/cancel`.
5. Backend:
   * Checks booking belongs to this customer.
   * If not completed, sets `status = 'cancelled'`.
6. Flutter updates booking card status.

---

## 5. Non-Functional Requirements

* **Security**
  * Passwords always hashed.
  * JWT for sessions.
  * Role-based checks on backend.

* **Performance**
  * Slot generation is simple O(N) per day, where N is number of slots.
  * Use indexes on frequently queried fields (`clinic`, `date`, `customer`).

* **Scalability**
  * Stateless backend → can be scaled horizontally.
  * MongoDB cluster can be scaled.

* **Extensibility**
  * Can later add:
    * Staff model & staff-specific slots.
    * Payments integration.
    * Notification system.
    * Multiple clinics per admin.

---

## 6. API Endpoints Summary

### Auth Routes
- `POST /api/auth/register` - Register user (customer/admin)
- `POST /api/auth/login` - Login and get JWT token

### Clinic Routes
- `POST /api/clinic` - Create clinic (admin only)
- `GET /api/clinic/:id` - Get clinic details (public)
- `PUT /api/clinic/:id` - Update clinic (admin owner only)

### Service Routes
- `GET /api/clinic/:clinicId/services` - Get services for clinic (public)
- `POST /api/services` - Create service (admin owner only)
- `PUT /api/services/:id` - Update service (admin owner only)
- `DELETE /api/services/:id` - Delete service (admin owner only)

### Booking Routes
- `GET /api/bookings/slots` - Get available slots (public, query: clinicId, date)
- `POST /api/bookings` - Create booking (customer only)
- `GET /api/bookings/my` - Get customer's bookings (customer only)
- `PATCH /api/bookings/:id/cancel` - Cancel booking (customer/admin)
- `PATCH /api/bookings/:id/status` - Update booking status (admin owner only)

### Admin Routes
- `GET /api/admin/bookings/today` - Get today's bookings (admin owner only, query: clinicId)
- `GET /api/admin/stats` - Get clinic stats (admin owner only, query: clinicId)

---

## 7. Project Structure

```
booking/
  backend/
    src/
      config/
      models/
      middleware/
      controllers/
      routes/
      utils/
  frontend/
    lib/
      core/
      models/
      screens/
      widgets/
  ARCHITECTURE.md
```

---

## 8. Development Principles

* Clean, efficient, and optimized code
* Production-ready implementation
* Complete features (nothing half-done)
* Clean up test/debug files after testing
* Stop and communicate if stuck
* Inform if something takes more time
* Follow security best practices
* Use proper error handling
* Maintain consistent code structure



