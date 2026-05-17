-- ============================================================
-- Student+ ERP — Master Schema
-- Supabase / PostgreSQL
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────
-- ENUM TYPES
-- ─────────────────────────────────────────
CREATE TYPE user_role AS ENUM ('student', 'staff', 'admin');
CREATE TYPE staff_sub_role AS ENUM ('subject_faculty', 'mentor', 'class_advisor');
CREATE TYPE attendance_status AS ENUM ('present', 'absent', 'late', 'od');
CREATE TYPE ml_od_type AS ENUM ('ML', 'OD');
CREATE TYPE approval_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE eligibility_status AS ENUM ('eligible', 'at_risk', 'detained');
CREATE TYPE assessment_type AS ENUM ('CIA1', 'CIA2', 'CIA3', 'assignment', 'practical', 'model', 'semester');
CREATE TYPE submission_status AS ENUM ('submitted', 'graded', 'late');
CREATE TYPE file_type AS ENUM ('pdf', 'ppt', 'video', 'doc', 'other');
CREATE TYPE notification_type AS ENUM ('circular', 'announcement', 'exam', 'fee', 'general');
CREATE TYPE fee_status AS ENUM ('pending', 'partial', 'paid');
CREATE TYPE exam_type AS ENUM ('CIA', 'model', 'semester');
CREATE TYPE calendar_event_type AS ENUM ('holiday', 'exam', 'event', 'semester_start', 'semester_end');
CREATE TYPE audit_action AS ENUM ('INSERT', 'UPDATE', 'DELETE');
CREATE TYPE counselling_type AS ENUM ('attendance', 'academic', 'personal', 'general');

-- ─────────────────────────────────────────
-- PROFILES  (mirrors auth.users)
-- ─────────────────────────────────────────
CREATE TABLE profiles (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email        TEXT UNIQUE NOT NULL,
  full_name    TEXT NOT NULL,
  phone        TEXT,
  role         user_role NOT NULL DEFAULT 'student',
  avatar_url   TEXT,
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- DEPARTMENTS
-- ─────────────────────────────────────────
CREATE TABLE departments (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT UNIQUE NOT NULL,
  code       TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- COURSES
-- ─────────────────────────────────────────
CREATE TABLE courses (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name           TEXT NOT NULL,
  department_id  UUID REFERENCES departments(id) ON DELETE SET NULL,
  duration_years INT NOT NULL DEFAULT 4,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- STUDENTS
-- ─────────────────────────────────────────
CREATE TABLE students (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id       UUID UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  register_no      TEXT UNIQUE NOT NULL,
  department_id    UUID REFERENCES departments(id),
  course_id        UUID REFERENCES courses(id),
  current_semester INT NOT NULL DEFAULT 1,
  batch            TEXT NOT NULL,
  section          TEXT,
  dob              DATE,
  gender           TEXT CHECK (gender IN ('M','F','Other')),
  address          TEXT,
  guardian_name    TEXT,
  guardian_phone   TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- STAFF
-- ─────────────────────────────────────────
CREATE TABLE staff (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id    UUID UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  employee_id   TEXT UNIQUE NOT NULL,
  department_id UUID REFERENCES departments(id),
  designation   TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- STAFF ROLES  (multi-role per staff)
-- ─────────────────────────────────────────
CREATE TABLE staff_roles (
  id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  role     staff_sub_role NOT NULL,
  UNIQUE (staff_id, role)
);

-- ─────────────────────────────────────────
-- SUBJECTS
-- ─────────────────────────────────────────
CREATE TABLE subjects (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code             TEXT UNIQUE NOT NULL,
  name             TEXT NOT NULL,
  department_id    UUID REFERENCES departments(id),
  course_id        UUID REFERENCES courses(id),
  semester_number  INT NOT NULL,
  credits          INT NOT NULL DEFAULT 3,
  is_practical     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- SUBJECT ASSIGNMENTS  (faculty → subject → class)
-- ─────────────────────────────────────────
CREATE TABLE subject_assignments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id      UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  staff_id        UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  academic_year   TEXT NOT NULL,
  semester_number INT NOT NULL,
  section         TEXT,
  batch           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (subject_id, staff_id, academic_year, semester_number, section)
);

-- ─────────────────────────────────────────
-- ENROLLMENTS  (student → subject)
-- ─────────────────────────────────────────
CREATE TABLE enrollments (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id            UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  subject_id            UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  subject_assignment_id UUID REFERENCES subject_assignments(id),
  academic_year         TEXT NOT NULL,
  semester_number       INT NOT NULL,
  enrolled_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, subject_id, academic_year, semester_number)
);

-- ─────────────────────────────────────────
-- TIMETABLE
-- ─────────────────────────────────────────
CREATE TABLE timetable (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_assignment_id UUID NOT NULL REFERENCES subject_assignments(id) ON DELETE CASCADE,
  day_of_week           INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7), -- 1=Mon
  period_number         INT NOT NULL,
  start_time            TIME NOT NULL,
  end_time              TIME NOT NULL,
  room                  TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- ATTENDANCE RAW
-- ─────────────────────────────────────────
CREATE TABLE attendance_raw (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id            UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  subject_id            UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  subject_assignment_id UUID REFERENCES subject_assignments(id),
  date                  DATE NOT NULL,
  period_number         INT,
  status                attendance_status NOT NULL,
  marked_by             UUID NOT NULL REFERENCES staff(id),
  marked_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  academic_year         TEXT NOT NULL,
  semester_number       INT NOT NULL,
  UNIQUE (student_id, subject_id, date, period_number, academic_year)
);

-- ─────────────────────────────────────────
-- ML / OD RECORDS
-- ─────────────────────────────────────────
CREATE TABLE ml_od (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id  UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  subject_id  UUID REFERENCES subjects(id), -- NULL = all subjects
  start_date  DATE NOT NULL,
  end_date    DATE NOT NULL,
  type        ml_od_type NOT NULL,
  reason      TEXT,
  approved_by UUID REFERENCES staff(id),
  approved_at TIMESTAMPTZ,
  status      approval_status NOT NULL DEFAULT 'pending',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- ATTENDANCE EFFECTIVE  (computed values)
-- ─────────────────────────────────────────
CREATE TABLE attendance_effective (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id             UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  subject_id             UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  academic_year          TEXT NOT NULL,
  semester_number        INT NOT NULL,
  total_classes          INT NOT NULL DEFAULT 0,
  present_count          INT NOT NULL DEFAULT 0,
  raw_percentage         DECIMAL(5,2) NOT NULL DEFAULT 0,
  ml_od_count            INT NOT NULL DEFAULT 0,
  effective_present_count INT NOT NULL DEFAULT 0,
  effective_percentage   DECIMAL(5,2) NOT NULL DEFAULT 0,
  is_ml_od_applicable    BOOLEAN NOT NULL DEFAULT FALSE,
  eligibility_status     eligibility_status NOT NULL DEFAULT 'eligible',
  last_calculated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, subject_id, academic_year, semester_number)
);

-- ─────────────────────────────────────────
-- ATTENDANCE RULES  (per academic year)
-- ─────────────────────────────────────────
CREATE TABLE attendance_rules (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  academic_year         TEXT UNIQUE NOT NULL,
  minimum_percentage    DECIMAL(5,2) NOT NULL DEFAULT 65.00,
  ml_od_max_days        INT NOT NULL DEFAULT 10,
  detention_threshold   DECIMAL(5,2) NOT NULL DEFAULT 65.00,
  risk_threshold        DECIMAL(5,2) NOT NULL DEFAULT 75.00,
  lock_attendance_date  DATE,
  created_by            UUID REFERENCES profiles(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- MARKS
-- ─────────────────────────────────────────
CREATE TABLE marks (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id            UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  subject_id            UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  subject_assignment_id UUID REFERENCES subject_assignments(id),
  academic_year         TEXT NOT NULL,
  semester_number       INT NOT NULL,
  assessment_type       assessment_type NOT NULL,
  max_marks             DECIMAL(6,2) NOT NULL,
  obtained_marks        DECIMAL(6,2),
  entered_by            UUID REFERENCES staff(id),
  entered_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, subject_id, academic_year, semester_number, assessment_type)
);

-- ─────────────────────────────────────────
-- ASSIGNMENTS
-- ─────────────────────────────────────────
CREATE TABLE assignments (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_assignment_id UUID NOT NULL REFERENCES subject_assignments(id) ON DELETE CASCADE,
  title                 TEXT NOT NULL,
  description           TEXT,
  due_date              TIMESTAMPTZ NOT NULL,
  max_marks             DECIMAL(6,2),
  created_by            UUID NOT NULL REFERENCES staff(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE assignment_submissions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id   UUID NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
  student_id      UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  submitted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  file_url        TEXT,
  marks_obtained  DECIMAL(6,2),
  feedback        TEXT,
  status          submission_status NOT NULL DEFAULT 'submitted',
  UNIQUE (assignment_id, student_id)
);

-- ─────────────────────────────────────────
-- STUDY MATERIALS
-- ─────────────────────────────────────────
CREATE TABLE study_materials (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_assignment_id UUID NOT NULL REFERENCES subject_assignments(id) ON DELETE CASCADE,
  title                 TEXT NOT NULL,
  description           TEXT,
  file_url              TEXT NOT NULL,
  file_type             file_type NOT NULL DEFAULT 'other',
  uploaded_by           UUID NOT NULL REFERENCES staff(id),
  uploaded_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- NOTIFICATIONS
-- ─────────────────────────────────────────
CREATE TABLE notifications (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title             TEXT NOT NULL,
  body              TEXT NOT NULL,
  type              notification_type NOT NULL DEFAULT 'general',
  target_role       user_role,         -- NULL = all roles
  target_department TEXT,              -- NULL = all departments
  created_by        UUID REFERENCES profiles(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at        TIMESTAMPTZ
);

CREATE TABLE notification_reads (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  profile_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  read_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (notification_id, profile_id)
);

-- ─────────────────────────────────────────
-- MENTOR MAPPING
-- ─────────────────────────────────────────
CREATE TABLE mentor_mapping (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mentor_staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  student_id      UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  academic_year   TEXT NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (mentor_staff_id, student_id, academic_year)
);

-- ─────────────────────────────────────────
-- CLASS ADVISOR MAPPING
-- ─────────────────────────────────────────
CREATE TABLE advisor_mapping (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  advisor_staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  department_id    UUID REFERENCES departments(id),
  semester_number  INT NOT NULL,
  section          TEXT,
  academic_year    TEXT NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- COUNSELLING NOTES
-- ─────────────────────────────────────────
CREATE TABLE counselling_notes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  staff_id   UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  note       TEXT NOT NULL,
  type       counselling_type NOT NULL DEFAULT 'attendance',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- FEES
-- ─────────────────────────────────────────
CREATE TABLE fees (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id    UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  academic_year TEXT NOT NULL,
  fee_type      TEXT NOT NULL,
  amount        DECIMAL(10,2) NOT NULL,
  due_date      DATE,
  paid_amount   DECIMAL(10,2) NOT NULL DEFAULT 0,
  paid_date     DATE,
  status        fee_status NOT NULL DEFAULT 'pending',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- EXAM SCHEDULE
-- ─────────────────────────────────────────
CREATE TABLE exam_schedule (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id      UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  academic_year   TEXT NOT NULL,
  semester_number INT NOT NULL,
  exam_type       exam_type NOT NULL,
  exam_date       DATE NOT NULL,
  start_time      TIME,
  end_time        TIME,
  venue           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- HALL TICKETS
-- ─────────────────────────────────────────
CREATE TABLE hall_tickets (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  academic_year   TEXT NOT NULL,
  semester_number INT NOT NULL,
  exam_type       exam_type NOT NULL,
  is_eligible     BOOLEAN NOT NULL DEFAULT FALSE,
  issued_at       TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, academic_year, semester_number, exam_type)
);

-- ─────────────────────────────────────────
-- ACADEMIC CALENDAR
-- ─────────────────────────────────────────
CREATE TABLE academic_calendar (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title         TEXT NOT NULL,
  description   TEXT,
  start_date    DATE NOT NULL,
  end_date      DATE,
  event_type    calendar_event_type NOT NULL DEFAULT 'event',
  academic_year TEXT NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- AUDIT LOGS
-- ─────────────────────────────────────────
CREATE TABLE audit_logs (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name   TEXT NOT NULL,
  record_id    UUID,
  action       audit_action NOT NULL,
  old_data     JSONB,
  new_data     JSONB,
  performed_by UUID REFERENCES profiles(id),
  performed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- INDEXES  (performance)
-- ─────────────────────────────────────────
CREATE INDEX idx_students_profile_id      ON students(profile_id);
CREATE INDEX idx_students_register_no     ON students(register_no);
CREATE INDEX idx_staff_profile_id         ON staff(profile_id);
CREATE INDEX idx_staff_roles_staff_id     ON staff_roles(staff_id);
CREATE INDEX idx_enrollments_student_id   ON enrollments(student_id);
CREATE INDEX idx_enrollments_subject_id   ON enrollments(subject_id);
CREATE INDEX idx_attendance_raw_student   ON attendance_raw(student_id, subject_id, academic_year);
CREATE INDEX idx_attendance_raw_date      ON attendance_raw(date);
CREATE INDEX idx_attendance_eff_student   ON attendance_effective(student_id, academic_year);
CREATE INDEX idx_ml_od_student            ON ml_od(student_id, status);
CREATE INDEX idx_marks_student            ON marks(student_id, subject_id, academic_year);
CREATE INDEX idx_mentor_mapping_mentor    ON mentor_mapping(mentor_staff_id, academic_year);
CREATE INDEX idx_mentor_mapping_student   ON mentor_mapping(student_id);
CREATE INDEX idx_notifications_role       ON notifications(target_role, created_at DESC);
CREATE INDEX idx_counselling_student      ON counselling_notes(student_id);
CREATE INDEX idx_fees_student             ON fees(student_id, academic_year);

-- ─────────────────────────────────────────
-- UPDATED_AT TRIGGER
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─────────────────────────────────────────
-- AUTO-CREATE PROFILE ON AUTH.USER INSERT
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'student')
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ─────────────────────────────────────────
-- SEED: DEFAULT ATTENDANCE RULES
-- ─────────────────────────────────────────
INSERT INTO attendance_rules (academic_year, minimum_percentage, ml_od_max_days, detention_threshold, risk_threshold)
VALUES ('2025-26', 65.00, 10, 65.00, 75.00)
ON CONFLICT (academic_year) DO NOTHING;
