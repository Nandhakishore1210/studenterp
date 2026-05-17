-- ============================================================
-- Student+ ERP — Row Level Security Policies
-- ============================================================

-- Enable RLS on every table
ALTER TABLE profiles             ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments          ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses              ENABLE ROW LEVEL SECURITY;
ALTER TABLE students             ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff                ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_roles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects             ENABLE ROW LEVEL SECURITY;
ALTER TABLE subject_assignments  ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments          ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetable            ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_raw       ENABLE ROW LEVEL SECURITY;
ALTER TABLE ml_od                ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_effective ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_rules     ENABLE ROW LEVEL SECURITY;
ALTER TABLE marks                ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignments          ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignment_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_materials      ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications        ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_reads   ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentor_mapping       ENABLE ROW LEVEL SECURITY;
ALTER TABLE advisor_mapping      ENABLE ROW LEVEL SECURITY;
ALTER TABLE counselling_notes    ENABLE ROW LEVEL SECURITY;
ALTER TABLE fees                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_schedule        ENABLE ROW LEVEL SECURITY;
ALTER TABLE hall_tickets         ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_calendar    ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs           ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────
-- HELPER FUNCTIONS
-- ─────────────────────────────────────────

-- Get current user's role
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS user_role LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$;

-- Check if current user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin');
$$;

-- Check if current user is staff
CREATE OR REPLACE FUNCTION is_staff()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'staff');
$$;

-- Check if current user is student
CREATE OR REPLACE FUNCTION is_student()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'student');
$$;

-- Get student id for current user
CREATE OR REPLACE FUNCTION my_student_id()
RETURNS UUID LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT id FROM students WHERE profile_id = auth.uid();
$$;

-- Get staff id for current user
CREATE OR REPLACE FUNCTION my_staff_id()
RETURNS UUID LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT id FROM staff WHERE profile_id = auth.uid();
$$;

-- Check if staff has a specific sub-role
CREATE OR REPLACE FUNCTION staff_has_role(p_staff_id UUID, p_role staff_sub_role)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (SELECT 1 FROM staff_roles WHERE staff_id = p_staff_id AND role = p_role);
$$;

-- Check if current staff user has a specific sub-role
CREATE OR REPLACE FUNCTION i_have_role(p_role staff_sub_role)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT staff_has_role(my_staff_id(), p_role);
$$;

-- Check if student is enrolled in a subject taught by current staff
CREATE OR REPLACE FUNCTION staff_teaches_student(p_student_id UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1
    FROM enrollments e
    JOIN subject_assignments sa ON sa.id = e.subject_assignment_id
    WHERE e.student_id = p_student_id
      AND sa.staff_id = my_staff_id()
  );
$$;

-- Check if student is a mentee of current staff
CREATE OR REPLACE FUNCTION is_my_mentee(p_student_id UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM mentor_mapping
    WHERE mentor_staff_id = my_staff_id()
      AND student_id = p_student_id
  );
$$;

-- ─────────────────────────────────────────
-- PROFILES
-- ─────────────────────────────────────────
CREATE POLICY "profiles_select_own_or_admin"
  ON profiles FOR SELECT
  USING (id = auth.uid() OR is_admin() OR is_staff());

CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  USING (id = auth.uid() OR is_admin());

CREATE POLICY "profiles_insert_admin"
  ON profiles FOR INSERT
  WITH CHECK (is_admin());

-- ─────────────────────────────────────────
-- DEPARTMENTS & COURSES  (read-only for all authenticated)
-- ─────────────────────────────────────────
CREATE POLICY "departments_read_all"
  ON departments FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "departments_write_admin"
  ON departments FOR ALL USING (is_admin());

CREATE POLICY "courses_read_all"
  ON courses FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "courses_write_admin"
  ON courses FOR ALL USING (is_admin());

-- ─────────────────────────────────────────
-- STUDENTS
-- ─────────────────────────────────────────
CREATE POLICY "students_select_own"
  ON students FOR SELECT
  USING (
    profile_id = auth.uid()
    OR is_admin()
    OR is_staff()
  );

CREATE POLICY "students_insert_admin"
  ON students FOR INSERT WITH CHECK (is_admin());

CREATE POLICY "students_update_admin"
  ON students FOR UPDATE USING (is_admin());

CREATE POLICY "students_delete_admin"
  ON students FOR DELETE USING (is_admin());

-- ─────────────────────────────────────────
-- STAFF
-- ─────────────────────────────────────────
CREATE POLICY "staff_select_all_authenticated"
  ON staff FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "staff_write_admin"
  ON staff FOR ALL USING (is_admin());

-- ─────────────────────────────────────────
-- STAFF ROLES
-- ─────────────────────────────────────────
CREATE POLICY "staff_roles_select_all"
  ON staff_roles FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "staff_roles_write_admin"
  ON staff_roles FOR ALL USING (is_admin());

-- ─────────────────────────────────────────
-- SUBJECTS
-- ─────────────────────────────────────────
CREATE POLICY "subjects_read_all"
  ON subjects FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "subjects_write_admin"
  ON subjects FOR ALL USING (is_admin());

-- ─────────────────────────────────────────
-- SUBJECT ASSIGNMENTS
-- ─────────────────────────────────────────
CREATE POLICY "subject_assignments_read_all"
  ON subject_assignments FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "subject_assignments_write_admin"
  ON subject_assignments FOR ALL USING (is_admin());

-- ─────────────────────────────────────────
-- ENROLLMENTS
-- ─────────────────────────────────────────
CREATE POLICY "enrollments_select"
  ON enrollments FOR SELECT
  USING (
    student_id = my_student_id()
    OR is_admin()
    OR (is_staff() AND (
      -- faculty sees students in their assigned subjects
      EXISTS (
        SELECT 1 FROM subject_assignments sa
        WHERE sa.id = subject_assignment_id AND sa.staff_id = my_staff_id()
      )
      OR i_have_role('mentor')
      OR i_have_role('class_advisor')
    ))
  );

CREATE POLICY "enrollments_write_admin"
  ON enrollments FOR ALL USING (is_admin());

-- ─────────────────────────────────────────
-- TIMETABLE
-- ─────────────────────────────────────────
CREATE POLICY "timetable_read_all"
  ON timetable FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "timetable_write_admin"
  ON timetable FOR ALL USING (is_admin());

-- ─────────────────────────────────────────
-- ATTENDANCE RAW
-- ─────────────────────────────────────────
CREATE POLICY "attendance_raw_student_own"
  ON attendance_raw FOR SELECT
  USING (
    student_id = my_student_id()
    OR is_admin()
    OR (is_staff() AND (
      EXISTS (
        SELECT 1 FROM subject_assignments sa
        WHERE sa.id = subject_assignment_id AND sa.staff_id = my_staff_id()
      )
      OR i_have_role('mentor')
      OR i_have_role('class_advisor')
    ))
  );

CREATE POLICY "attendance_raw_faculty_insert"
  ON attendance_raw FOR INSERT
  WITH CHECK (
    is_admin()
    OR (is_staff() AND marked_by = my_staff_id())
  );

CREATE POLICY "attendance_raw_faculty_update"
  ON attendance_raw FOR UPDATE
  USING (
    is_admin()
    OR (is_staff() AND marked_by = my_staff_id())
  );

CREATE POLICY "attendance_raw_admin_delete"
  ON attendance_raw FOR DELETE USING (is_admin());

-- ─────────────────────────────────────────
-- ML / OD
-- ─────────────────────────────────────────
CREATE POLICY "ml_od_select"
  ON ml_od FOR SELECT
  USING (
    student_id = my_student_id()
    OR is_admin()
    OR (is_staff() AND (
      is_my_mentee(student_id)
      OR i_have_role('class_advisor')
      OR staff_teaches_student(student_id)
    ))
  );

CREATE POLICY "ml_od_insert_admin_or_staff"
  ON ml_od FOR INSERT
  WITH CHECK (is_admin() OR is_staff());

CREATE POLICY "ml_od_update_admin_or_approver"
  ON ml_od FOR UPDATE
  USING (is_admin() OR (is_staff() AND i_have_role('mentor')));

-- ─────────────────────────────────────────
-- ATTENDANCE EFFECTIVE
-- ─────────────────────────────────────────
CREATE POLICY "attendance_eff_select"
  ON attendance_effective FOR SELECT
  USING (
    student_id = my_student_id()
    OR is_admin()
    OR (is_staff() AND (
      staff_teaches_student(student_id)
      OR is_my_mentee(student_id)
      OR i_have_role('class_advisor')
    ))
  );

-- Only edge functions / service role update this
CREATE POLICY "attendance_eff_service_write"
  ON attendance_effective FOR ALL
  USING (is_admin());

-- ─────────────────────────────────────────
-- ATTENDANCE RULES
-- ─────────────────────────────────────────
CREATE POLICY "attendance_rules_read_all"
  ON attendance_rules FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "attendance_rules_write_admin"
  ON attendance_rules FOR ALL USING (is_admin());

-- ─────────────────────────────────────────
-- MARKS
-- ─────────────────────────────────────────
CREATE POLICY "marks_student_own"
  ON marks FOR SELECT
  USING (
    student_id = my_student_id()
    OR is_admin()
    OR (is_staff() AND (
      staff_teaches_student(student_id)
      OR is_my_mentee(student_id)
      OR i_have_role('class_advisor')
    ))
  );

CREATE POLICY "marks_faculty_insert"
  ON marks FOR INSERT
  WITH CHECK (is_admin() OR (is_staff() AND entered_by = my_staff_id()));

CREATE POLICY "marks_faculty_update"
  ON marks FOR UPDATE
  USING (is_admin() OR (is_staff() AND entered_by = my_staff_id()));

-- ─────────────────────────────────────────
-- ASSIGNMENTS
-- ─────────────────────────────────────────
CREATE POLICY "assignments_read"
  ON assignments FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "assignments_faculty_write"
  ON assignments FOR ALL
  USING (is_admin() OR (is_staff() AND created_by = my_staff_id()));

CREATE POLICY "assignments_insert_faculty"
  ON assignments FOR INSERT
  WITH CHECK (is_admin() OR (is_staff() AND created_by = my_staff_id()));

-- ─────────────────────────────────────────
-- ASSIGNMENT SUBMISSIONS
-- ─────────────────────────────────────────
CREATE POLICY "submissions_select"
  ON assignment_submissions FOR SELECT
  USING (
    student_id = my_student_id()
    OR is_admin()
    OR is_staff()
  );

CREATE POLICY "submissions_student_insert"
  ON assignment_submissions FOR INSERT
  WITH CHECK (student_id = my_student_id() OR is_admin());

CREATE POLICY "submissions_faculty_update"
  ON assignment_submissions FOR UPDATE
  USING (is_admin() OR is_staff());

-- ─────────────────────────────────────────
-- STUDY MATERIALS
-- ─────────────────────────────────────────
CREATE POLICY "materials_read_all"
  ON study_materials FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "materials_faculty_write"
  ON study_materials FOR ALL
  USING (is_admin() OR (is_staff() AND uploaded_by = my_staff_id()));

CREATE POLICY "materials_faculty_insert"
  ON study_materials FOR INSERT
  WITH CHECK (is_admin() OR (is_staff() AND uploaded_by = my_staff_id()));

-- ─────────────────────────────────────────
-- NOTIFICATIONS
-- ─────────────────────────────────────────
CREATE POLICY "notifications_read"
  ON notifications FOR SELECT
  USING (
    auth.uid() IS NOT NULL AND (
      target_role IS NULL
      OR target_role = get_my_role()
    )
  );

CREATE POLICY "notifications_write_admin_staff"
  ON notifications FOR ALL
  USING (is_admin() OR is_staff());

CREATE POLICY "notifications_insert_admin_staff"
  ON notifications FOR INSERT
  WITH CHECK (is_admin() OR is_staff());

-- ─────────────────────────────────────────
-- NOTIFICATION READS
-- ─────────────────────────────────────────
CREATE POLICY "notification_reads_own"
  ON notification_reads FOR ALL
  USING (profile_id = auth.uid());

CREATE POLICY "notification_reads_insert_own"
  ON notification_reads FOR INSERT
  WITH CHECK (profile_id = auth.uid());

-- ─────────────────────────────────────────
-- MENTOR MAPPING
-- ─────────────────────────────────────────
CREATE POLICY "mentor_mapping_read"
  ON mentor_mapping FOR SELECT
  USING (
    mentor_staff_id = my_staff_id()
    OR student_id = my_student_id()
    OR is_admin()
  );

CREATE POLICY "mentor_mapping_write_admin"
  ON mentor_mapping FOR ALL USING (is_admin());

-- ─────────────────────────────────────────
-- ADVISOR MAPPING
-- ─────────────────────────────────────────
CREATE POLICY "advisor_mapping_read"
  ON advisor_mapping FOR SELECT
  USING (advisor_staff_id = my_staff_id() OR is_admin());

CREATE POLICY "advisor_mapping_write_admin"
  ON advisor_mapping FOR ALL USING (is_admin());

-- ─────────────────────────────────────────
-- COUNSELLING NOTES
-- ─────────────────────────────────────────
CREATE POLICY "counselling_notes_read"
  ON counselling_notes FOR SELECT
  USING (
    staff_id = my_staff_id()
    OR student_id = my_student_id()
    OR is_admin()
  );

CREATE POLICY "counselling_notes_insert_staff"
  ON counselling_notes FOR INSERT
  WITH CHECK (is_staff() AND staff_id = my_staff_id() OR is_admin());

CREATE POLICY "counselling_notes_update_staff"
  ON counselling_notes FOR UPDATE
  USING (staff_id = my_staff_id() OR is_admin());

-- ─────────────────────────────────────────
-- FEES
-- ─────────────────────────────────────────
CREATE POLICY "fees_student_own"
  ON fees FOR SELECT
  USING (student_id = my_student_id() OR is_admin());

CREATE POLICY "fees_write_admin"
  ON fees FOR ALL USING (is_admin());

-- ─────────────────────────────────────────
-- EXAM SCHEDULE
-- ─────────────────────────────────────────
CREATE POLICY "exam_schedule_read_all"
  ON exam_schedule FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "exam_schedule_write_admin"
  ON exam_schedule FOR ALL USING (is_admin());

-- ─────────────────────────────────────────
-- HALL TICKETS
-- ─────────────────────────────────────────
CREATE POLICY "hall_tickets_read"
  ON hall_tickets FOR SELECT
  USING (student_id = my_student_id() OR is_admin() OR is_staff());

CREATE POLICY "hall_tickets_write_admin"
  ON hall_tickets FOR ALL USING (is_admin());

-- ─────────────────────────────────────────
-- ACADEMIC CALENDAR
-- ─────────────────────────────────────────
CREATE POLICY "academic_calendar_read_all"
  ON academic_calendar FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "academic_calendar_write_admin"
  ON academic_calendar FOR ALL USING (is_admin());

-- ─────────────────────────────────────────
-- AUDIT LOGS
-- ─────────────────────────────────────────
CREATE POLICY "audit_logs_read_admin"
  ON audit_logs FOR SELECT USING (is_admin());

CREATE POLICY "audit_logs_insert_all"
  ON audit_logs FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
