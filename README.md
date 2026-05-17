# Student+ ERP

A full-scale campus ERP mobile application built with **Flutter** (frontend) and **Supabase** (backend), functionally equivalent to MyCamu.

---

## Project Structure

```
attendance/
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   │   ├── 00001_schema.sql       ← All database tables
│   │   ├── 00002_rls.sql          ← Row Level Security policies
│   │   └── 00003_functions.sql    ← DB functions, triggers, views
│   └── functions/
│       ├── calculate-attendance/  ← Edge Function: recalculate attendance
│       └── approve-ml-od/         ← Edge Function: approve ML/OD
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/             ← Colors, Supabase keys, strings
│   │   ├── theme/                 ← Material 3 theme
│   │   ├── router/                ← GoRouter with role-based guards
│   │   └── utils/                 ← Attendance calculations, date utils
│   ├── data/
│   │   ├── models/                ← Dart model classes
│   │   ├── services/              ← SupabaseService (all DB calls)
│   │   └── repositories/          ← (extend as needed)
│   ├── features/
│   │   ├── auth/                  ← Login, Forgot Password, Auth provider
│   │   ├── student/               ← 11 screens + provider
│   │   ├── staff/                 ← 7 screens + provider
│   │   └── admin/                 ← 5 screens + provider
│   └── shared/
│       └── widgets/               ← Reusable widgets
└── pubspec.yaml
```

---

## Setup Instructions

### 1. Supabase Project Setup

1. Go to [supabase.com](https://supabase.com) → New Project
2. Go to **SQL Editor** → run the migrations in order:
   ```
   supabase/migrations/00001_schema.sql
   supabase/migrations/00002_rls.sql
   supabase/migrations/00003_functions.sql
   ```
3. Go to **Storage** → create buckets:
   - `study-materials` (public)
   - `submissions` (private)
   - `avatars` (public)
4. Go to **Edge Functions** → deploy:
   - `supabase/functions/calculate-attendance/`
   - `supabase/functions/approve-ml-od/`

### 2. Flutter Setup

1. Copy your Supabase URL and anon key from **Project Settings → API**
2. Edit `lib/core/constants/supabase_constants.dart`:
   ```dart
   static const String supabaseUrl  = 'https://YOUR_PROJECT.supabase.co';
   static const String supabaseAnonKey = 'YOUR_ANON_KEY';
   ```
3. Update `currentAcademicYear` and `currentSemester` as needed.

4. Install dependencies:
   ```bash
   flutter pub get
   ```

5. Run:
   ```bash
   flutter run
   ```

---

## Roles & Features

| Role | Features |
|------|---------|
| **Student** | Dashboard, Attendance (with ML/OD indicator), Marks, Timetable, Assignments, Materials, Fees, Notifications, Results, Exam Schedule, Profile |
| **Staff – Faculty** | Subject list, Mark Attendance, Enter Marks, Upload Materials, Manage Assignments, Reports (with filter) |
| **Staff – Mentor** | All Faculty features + Performa tab (mentee analytics, counselling notes) |
| **Staff – Class Advisor** | All Faculty features + Performa tab for assigned class |
| **Admin** | Dashboard, User Management, Academic Setup, Attendance Rules, Analytics (pie chart, dept breakdown) |

---

## Attendance Intelligence

| Raw % | ML/OD Applied? | Status |
|-------|---------------|--------|
| ≥ 75% | ✅ Yes | 🟢 Good Standing |
| 65–74% | ✅ Yes | 🟡 At Risk |
| < 65% | ❌ No | 🔴 Detained |

**Rule:** ML/OD adjustments are **only counted** when raw attendance ≥ 65%.  
This is enforced in `supabase/migrations/00003_functions.sql` → `calculate_effective_attendance()`.  
No manual override is permitted from the frontend.

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x, Dart 3.x |
| State Management | flutter_riverpod |
| Navigation | go_router |
| Backend | Supabase (PostgreSQL, Auth, Storage, Edge Functions) |
| Charts | fl_chart |
| UI | Material 3, Google Fonts (Inter) |

---

## Database Tables

`profiles`, `departments`, `courses`, `students`, `staff`, `staff_roles`,
`subjects`, `subject_assignments`, `enrollments`, `timetable`,
`attendance_raw`, `ml_od`, `attendance_effective`, `attendance_rules`,
`marks`, `assignments`, `assignment_submissions`, `study_materials`,
`notifications`, `notification_reads`, `mentor_mapping`, `advisor_mapping`,
`counselling_notes`, `fees`, `exam_schedule`, `hall_tickets`,
`academic_calendar`, `audit_logs`

---

## Security

- All tables protected by **Row Level Security (RLS)**
- Students can only read their own data
- Faculty can only access students in their assigned subjects
- Mentors can only access their assigned mentees
- Admin has full access
- Attendance calculation runs server-side only (no client manipulation)
- All attendance changes are audit-logged

---

## Final Year Project Note

This system covers all mandatory ERP modules as specified in the master prompt:
Authentication, Student Dashboard, Staff Multi-Role, Admin Control Panel,
ML/OD Intelligence, Mentor Performa, Analytics, and complete Supabase backend.
