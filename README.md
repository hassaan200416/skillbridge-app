<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.27+-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/Deployed-Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white" />
  <img src="https://img.shields.io/badge/AI-Groq_LPU-F55036?style=for-the-badge" />
</p>

<h1 align="center">SkillBridge</h1>

<p align="center">
  A production-deployed local services marketplace for Pakistan — connecting customers with skilled providers across Karachi, Lahore, and Islamabad.
</p>

<p align="center">
  <a href="https://skillbridge-app-beta.vercel.app"><strong>View Live Demo →</strong></a>
</p>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Database Schema](#database-schema)
- [Getting Started](#getting-started)
- [Deployment](#deployment)
- [Design System](#design-system)
- [Test Accounts](#test-accounts)

---

## Overview

SkillBridge is a full-stack Flutter web application with three distinct user roles — **Customer**, **Provider**, and **Admin** — each with a dedicated responsive interface. The platform handles the complete service lifecycle: discovery, booking, payment tracking, real-time communication, and post-service reviews.

Built with a clean architecture pattern, Supabase as the backend-as-a-service layer, and Groq AI for natural language features. Deployed on Vercel with automatic CI/CD on every push.

---

## Features

<details>
<summary><strong>Customer</strong></summary>

- AI-powered natural language search — query like _"affordable plumber under 3000"_
- Browse services by category, city, and price
- Book services with date and time slot selection
- Real-time chat with service providers
- Personal wishlist for saving services
- Write, edit, and submit reviews on completed bookings
- Flag inappropriate reviews for moderation
- View full provider profiles with ratings and service history
- SkillBot — AI assistant for platform guidance
- Real-time in-app notifications for all booking events
- Platform announcements with per-user dismiss

</details>

<details>
<summary><strong>Provider</strong></summary>

- Create and manage service listings with multi-image upload
- Accept, reject, or complete incoming booking requests
- Analytics dashboard — revenue, booking trends, category breakdown
- Real-time chat with customers
- Review monitoring across all services
- SkillBot — AI assistant with provider-specific context
- Full profile management — bio, experience, service area, portfolio

</details>

<details>
<summary><strong>Admin</strong></summary>

- Platform-wide analytics — users, bookings, revenue
- User management — verify providers, suspend accounts
- Service moderation — activate or deactivate any listing
- Review moderation — manage flagged reviews
- Full booking oversight across all providers
- Broadcast announcements to all users

</details>

<details>
<summary><strong>AI — Powered by Groq</strong></summary>

| Feature               | Description                                                                                                          |
| --------------------- | -------------------------------------------------------------------------------------------------------------------- |
| **Smart Search**      | Parses natural language into structured filters (category + max price). Active AI curation shown via a visual banner |
| **Review Summarizer** | Generates a 2–3 sentence summary for services with 3+ reviews. Cached 24h in `services.ai_summary`                   |
| **SkillBot**          | Floating contextual chatbot — blue for customers, teal for providers. Scoped to platform questions only              |

> Groq (`llama-3.1-8b-instant`) is used over Gemini because Google's free tier is geo-blocked in Pakistan. Groq provides unrestricted inference via LPU hardware using an OpenAI-compatible endpoint.

</details>

---

## Tech Stack

| Layer            | Technology                                          |
| ---------------- | --------------------------------------------------- |
| Frontend         | Flutter 3.27+                                       |
| State Management | Riverpod                                            |
| Routing          | go_router                                           |
| Backend          | Supabase — PostgreSQL, Auth, Storage, Realtime, RLS |
| AI               | Groq API — `llama-3.1-8b-instant`                   |
| Charts           | fl_chart                                            |
| Fonts            | Google Fonts — Poppins + Inter                      |
| Deployment       | Vercel                                              |

---

## Architecture

```
lib/
├── core/
│   ├── constants/         # Design tokens, route names, strings
│   ├── errors/            # Typed failure classes
│   └── layout/            # AppBreakpoints (compact <600, expanded ≥800)
├── data/
│   ├── models/            # UserModel, ServiceModel, BookingModel, ReviewModel …
│   └── repositories/      # Supabase data access — one repo per domain
├── presentation/
│   ├── navigation/        # app_router.dart — ShellRoutes + GoRouter config
│   ├── providers/         # Riverpod providers (FutureProvider, StateProvider)
│   ├── screens/
│   │   ├── admin/         # 11 screens — dashboard through settings
│   │   ├── auth/          # Login, register, verify, profile setup
│   │   ├── customer/      # 15 screens — home through profile
│   │   ├── provider/      # 11 screens — dashboard through profile edit
│   │   └── shared/        # Splash, 404, chat detail, announcements
│   └── widgets/
│       ├── common/        # AppSidebar, AppTopBar, SkillBot, service cards
│       └── service/       # Service-specific shared components
└── services/
    ├── ai_service.dart        # Groq — search parsing, review summary, chatbot
    ├── storage_service.dart   # Supabase Storage — image uploads
    └── supabase_service.dart  # Supabase client singleton
```

### Shell Pattern

All three roles share a unified shell architecture defined in `app_router.dart`. Each shell has its own `GlobalKey<NavigatorState>` to prevent navigator conflicts.

```
AppSidebar       240px expanded / 80px collapsed, role-based nav, shared sidebarExpandedProvider
AppTopBar        Search (role-aware) + notification bell + profile dropdown
CustomerShell    Web: sidebar + topbar  |  Mobile: bottom nav + More sheet
ProviderShell    Web: sidebar + topbar  |  Mobile: bottom nav + More sheet
AdminShell       Web: sidebar + topbar  |  Mobile: bottom nav + More sheet
```

**Screens inside a shell** render content only — no `Scaffold`.  
**Standalone screens** (service detail, booking detail, chat) use `Material(color: _kBg)` as root.

### Routing Rules

```dart
// Static paths MUST precede dynamic paths
GoRoute(path: '/book/confirm', ...),  // before /book/:id
GoRoute(path: '/book/:id', ...),
GoRoute(path: '/service/add', ...),   // before /service/:id
GoRoute(path: '/service/:id', ...),

// Always use context.go() — never context.push()
// context.push() causes GlobalKey conflicts with shell navigators
```

---

## Database Schema

### Tables

| Table                     | Description                                                                                                                                      |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `users`                   | All roles. Includes `role`, `is_verified`, `is_suspended`, `suspension_reason`, `is_profile_complete`                                            |
| `services`                | Listings. `price_type`: `fixed` or `startingFrom`. Denormalized `avg_rating`, `review_count`, `booking_count`                                    |
| `bookings`                | Status flow: `pending → confirmed → completed / cancelled / disputed`. Snapshot `price_at_booking`. `time_slot`: `morning / afternoon / evening` |
| `reviews`                 | One per booking (unique constraint on `booking_id`). `flag_count`, `is_flagged`, `is_editable`                                                   |
| `notifications`           | `data JSONB` carries destination route for deep-link navigation                                                                                  |
| `conversations`           | Customer–provider pairs per service. Stores `last_message` preview                                                                               |
| `messages`                | Individual chat messages with `is_read` + Realtime streaming                                                                                     |
| `announcements`           | Admin broadcasts. `title`, `body`, `created_by`                                                                                                  |
| `saved_services`          | Wishlist. Composite PK: `user_id + service_id`                                                                                                   |
| `dismissed_announcements` | Per-user dismiss tracking. Composite PK: `user_id + announcement_id`                                                                             |
| `review_flags`            | Flag tracking. Composite PK: `user_id + review_id`                                                                                               |

### Triggers

| Trigger                              | Fires On                                                               |
| ------------------------------------ | ---------------------------------------------------------------------- |
| `handle_new_user()`                  | `auth.users` INSERT → creates `public.users` row                       |
| `handle_booking_notification()`      | Booking status change → notification INSERT                            |
| `notify_admin_new_user()`            | New user registration → admin notification                             |
| `recalculate_service_rating()`       | Review INSERT / UPDATE / DELETE → updates `avg_rating`, `review_count` |
| `update_booking_count()`             | Booking → completed → increments `booking_count`                       |
| `update_conversation_last_message()` | Message INSERT → updates conversation preview                          |
| `notify_new_message()`               | Message INSERT → notification to recipient                             |
| `update_review_flag_count()`         | `review_flags` INSERT → updates `flag_count`, `is_flagged`             |
| `updated_at` triggers                | Any UPDATE → refreshes `updated_at` timestamp                          |

### Row Level Security

Access control is enforced at the PostgreSQL level — not just in application code. Every table has RLS policies. Examples:

```sql
-- Anyone can read active, published services
CREATE POLICY "Public read active services" ON services
  FOR SELECT USING (is_active = true AND is_draft = false);

-- Providers can only update their own services
CREATE POLICY "Provider updates own services" ON services
  FOR UPDATE USING (auth.uid() = provider_id);

-- Users see only their own notifications
CREATE POLICY "User reads own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);
```

---

## Getting Started

### Prerequisites

- [Flutter SDK 3.27+](https://flutter.dev/docs/get-started/install)
- [Supabase project](https://supabase.com)
- [Groq API key](https://console.groq.com) — free, no geo-restrictions

### Installation

```bash
# 1. Clone
git clone https://github.com/your-username/skillbridge.git
cd skillbridge

# 2. Environment — Flutter web reads from assets/app.env
cat > assets/app.env << EOF
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GROQ_API_KEY=your-groq-api-key
EOF

# 3. Install dependencies
flutter pub get

# 4. Run
flutter run -d chrome
```

> `main.dart` uses `kIsWeb ? 'assets/app.env' : '.env'` for environment loading. Ensure `assets/app.env` is declared in `pubspec.yaml`.

---

## Deployment

The project is configured for zero-config Vercel deployment.

```
build.sh        Injects env vars → installs Flutter → flutter build web --release
vercel.json     Build command, output directory (build/web), SPA rewrites
```

**Environment variables** — set in the Vercel dashboard:

```
SUPABASE_URL
SUPABASE_ANON_KEY
GROQ_API_KEY
```

Every push to `main` triggers an automatic rebuild. No manual steps required.

---

## Design System

| Token        | Value     |
| ------------ | --------- |
| Primary      | `#2D9B6F` |
| Secondary    | `#1A2B3C` |
| Background   | `#F5F7FA` |
| Border       | `#E2E8F0` |
| Muted        | `#64748B` |
| Heading Font | Poppins   |
| Body Font    | Inter     |
| Currency     | PKR       |

### Status Badges

| Status    | Background | Text      |
| --------- | ---------- | --------- |
| Pending   | `#FEF3C7`  | `#D97706` |
| Confirmed | `#D1FAE5`  | `#065F46` |
| Completed | `#DBEAFE`  | `#1E40AF` |
| Cancelled | `#FEE2E2`  | `#991B1B` |

---

## Test Accounts

| Role     | Email                      |
| -------- | -------------------------- |
| Admin    | hassaanraheel221@gmail.com |
| Provider | airbone221@gmail.com       |
| Customer | ali@gmail.com              |

---

<p align="center">
  Built with Flutter · Powered by Supabase · AI by Groq
</p>
