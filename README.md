# SkillBridge

A full-stack Flutter web application that connects customers with local service providers across Pakistan. Built as a semester project for BS IT at Bahria University.

**Live Demo:** [skillbridge-app-beta.vercel.app](https://skillbridge-app-beta.vercel.app)

---

## Overview

SkillBridge is a local services marketplace targeting three major Pakistani cities — Karachi, Lahore, and Islamabad. The platform enables customers to discover, book, and review skilled service providers, while providers can manage their listings, track bookings, and grow their business. An admin dashboard provides full platform oversight with analytics, user management, and moderation tools.

The application features three distinct user roles, each with a dedicated interface, real-time notifications, an AI-powered assistant, and a built-in chat system for direct customer-provider communication.

---

## Features

### Customer Features

- Browse and search services with AI-powered natural language search
- Book services with date and time slot selection
- Real-time chat with service providers
- Save services to a personal wishlist
- Write and manage reviews for completed bookings
- Flag inappropriate reviews for admin moderation
- View provider profiles with ratings and service history
- AI chatbot (SkillBot) for platform assistance
- Receive real-time notifications for booking updates

### Provider Features

- Create and manage service listings with image galleries
- Accept, reject, or complete incoming bookings
- Performance analytics dashboard with earnings charts
- View and respond to customer reviews
- Real-time chat with customers
- AI chatbot (SkillBot) for provider-specific guidance
- Track booking trends and revenue over time

### Admin Features

- Platform-wide analytics with user, booking, and revenue metrics
- User management with verify and suspend capabilities
- Service moderation with activate/deactivate controls
- Review moderation with flagged review management
- Booking oversight across all providers
- Broadcast platform announcements to all users
- Notification management

### AI Features (Powered by Groq)

- **Smart Search** — Natural language queries are parsed into structured filters (category, price range) using AI, displayed with a visual banner indicating active AI curation
- **Review Summaries** — Services with 3+ reviews get an AI-generated summary paragraph, cached for 24 hours in the database
- **SkillBot** — Contextual AI assistant available for customers (blue theme) and providers (teal theme), scoped strictly to platform-related questions

---

## Tech Stack

| Layer            | Technology                                          |
| ---------------- | --------------------------------------------------- |
| Frontend         | Flutter (Dart, null safety)                         |
| State Management | Riverpod                                            |
| Routing          | go_router                                           |
| Backend          | Supabase (PostgreSQL, Auth, Storage, Realtime, RLS) |
| AI               | Groq API (llama-3.1-8b-instant)                     |
| Charts           | fl_chart                                            |
| Deployment       | Vercel (auto-deploy on git push)                    |

---

## Project Architecture

The project follows a clean architecture pattern with clear separation of concerns:

```
lib/
├── core/                  # Constants, error types, route definitions
│   ├── constants/         # Colors, strings, text styles, route names
│   └── errors/            # Failure classes for error handling
├── data/                  # Data layer (backend logic)
│   ├── models/            # Data models (UserModel, ServiceModel, BookingModel, etc.)
│   └── repositories/      # Supabase CRUD operations and business logic
├── presentation/          # UI layer (frontend logic)
│   ├── navigation/        # Router configuration and shell widgets
│   ├── providers/         # Riverpod state management providers
│   ├── screens/           # All screen widgets organized by role
│   │   ├── admin/         # Admin dashboard, users, services, bookings, reviews, analytics
│   │   ├── auth/          # Login, register, verify email, profile setup
│   │   ├── customer/      # Home, search, service detail, bookings, profile, reviews
│   │   ├── provider/      # Dashboard, services, bookings, analytics, reviews, profile
│   │   └── shared/        # Splash, not found, announcements, chat screens
│   └── widgets/           # Reusable UI components
│       ├── common/        # Sidebar, top bar, SkillBot, service cards
│       └── service/       # Service-specific shared widgets
└── services/              # External service integrations
    ├── ai_service.dart    # Groq AI integration (search, summaries, chatbot)
    ├── storage_service.dart # Supabase Storage for image uploads
    └── supabase_service.dart # Supabase client singleton
```

### Shell Pattern

All three roles use a unified shell architecture:

- **AppSidebar** — Collapsible sidebar (240px expanded / 80px collapsed) with role-based navigation items
- **AppTopBar** — Header with hamburger toggle, role-aware search bar, notification bell with popover, and profile avatar dropdown
- **CustomerShell / ProviderShell / AdminShell** — Role-specific shells that provide sidebar + top bar on desktop (≥800px) and bottom navigation on mobile

Screens inside shells return content directly without their own Scaffold. Standalone detail screens (service detail, booking detail, chat detail) have their own Scaffold with sidebar and top bar.

---

## Database Schema

### Core Tables

- **users** — User profiles with role (customer/provider/admin), verification status, suspension management, and profile fields
- **services** — Service listings with category, pricing (fixed/starting from), availability days, image URLs, and denormalized rating/booking counts
- **bookings** — Booking records with status workflow (pending → confirmed → completed/cancelled), time slots (morning/afternoon/evening), and price snapshots
- **reviews** — Customer reviews with ratings, flag system for moderation (flag_count, is_flagged, flag_reason)
- **notifications** — In-app notifications with type-based routing and read status
- **conversations** — Chat conversations between customer-provider pairs
- **messages** — Individual chat messages with read status and real-time streaming
- **announcements** — Admin broadcast messages with active/expiry controls
- **saved_services** — Customer wishlist (composite PK: user_id + service_id)
- **dismissed_announcements** — Tracks which users dismissed which announcements
- **review_flags** — Tracks which users flagged which reviews

### Database Triggers

- `handle_new_user()` — Creates public user record on auth signup
- `handle_booking_notification()` — Sends notifications on booking status changes
- `notify_admin_new_user()` — Notifies admins of new user registrations
- `recalculate_service_rating()` — Updates service avg_rating and review_count on review changes
- `update_booking_count()` — Increments service booking_count on completed bookings
- `update_conversation_last_message()` — Updates conversation preview on new messages
- `notify_new_message()` — Sends notification to recipient on new chat messages
- `update_review_flag_count()` — Updates review flag status when users flag reviews

### Row Level Security

Every table uses Supabase RLS policies to enforce access control at the database level. Users can only read/write data they are authorized to access based on their role and ownership.

---

## Getting Started

### Prerequisites

- Flutter SDK 3.27+
- Dart SDK (included with Flutter)
- A Supabase project
- A Groq API key (free at [console.groq.com](https://console.groq.com))

### Environment Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/skillbridge.git
   cd skillbridge
   ```

2. Create `assets/app.env` with your credentials:

   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   GROQ_API_KEY=your-groq-api-key
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run -d chrome
   ```

### Deployment (Vercel)

The project is configured for Vercel auto-deployment:

- `build.sh` at project root generates `assets/app.env` from Vercel environment variables, installs the Flutter SDK, and runs the web build
- `vercel.json` configures the build and output settings
- Environment variables (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GROQ_API_KEY`) are set in the Vercel dashboard
- Every `git push` triggers an automatic rebuild and deployment

---

## Test Accounts

| Role     | Email                      | Description                            |
| -------- | -------------------------- | -------------------------------------- |
| Admin    | hassaanraheel221@gmail.com | Full platform management access        |
| Provider | airbone221@gmail.com       | Verified provider with seeded services |
| Customer | ali@gmail.com              | Customer account for testing bookings  |

---

## Design System

| Token        | Value                  |
| ------------ | ---------------------- |
| Primary      | `#2D9B6F`              |
| Secondary    | `#1A2B3C`              |
| Background   | `#F5F7FA`              |
| Border       | `#E2E8F0`              |
| Heading Font | Poppins (Google Fonts) |
| Body Font    | Inter (Google Fonts)   |
| Currency     | PKR (Pakistani Rupee)  |

### Status Badges

| Status    | Background | Text      |
| --------- | ---------- | --------- |
| Pending   | `#FEF3C7`  | `#D97706` |
| Confirmed | `#D1FAE5`  | `#065F46` |
| Completed | `#DBEAFE`  | `#1E40AF` |
| Cancelled | `#FEE2E2`  | `#991B1B` |

---

## Screen Count

| Role      | Shell Screens | Standalone Screens | Total  |
| --------- | ------------- | ------------------ | ------ |
| Auth      | —             | 4                  | 4      |
| Customer  | 8             | 6                  | 14     |
| Provider  | 4             | 5                  | 9      |
| Admin     | 10            | 1                  | 11     |
| Shared    | —             | 4                  | 4      |
| **Total** |               |                    | **42** |

---

## Key Technical Decisions

- **No fake data** — Every UI element maps to a real database field. The professor inspects DevTools; simpler honest UI beats impressive fake UI.
- **Groq over Gemini** — Google Gemini free tier is geo-blocked in Pakistan (quota = 0). Groq provides genuinely free AI with no geo-restrictions via LPU hardware.
- **Supabase RLS** — All access control is enforced at the database level, not just in application code.
- **Denormalized counters** — `avg_rating`, `review_count`, and `booking_count` are stored on the services table and updated by triggers for fast reads.
- **Time slots over time pickers** — Booking uses morning/afternoon/evening enum values, not hh:mm ranges, matching how local services in Pakistan typically operate.
- **Static routes before dynamic** — In go_router, static routes like `/book/confirm` must precede dynamic routes like `/book/:id` to prevent UUID conflicts.

---

---
