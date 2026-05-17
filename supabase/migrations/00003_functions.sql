-- ============================================================
-- Student+ ERP — Database Functions & Triggers
-- Called by Edge Functions and internal logic
-- ============================================================

-- ─────────────────────────────────────────
-- CALCULATE EFFECTIVE ATTENDANCE FOR ONE STUDENT/SUBJECT
-- Called by the Edge Function after attendance is marked
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION calculate_effective_attendance(
  p_student_id    UUID,
  p_subject_id    UUID,
  p_academic_year TEXT,
  p_semester_no   INT
)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_total_classes     INT;
  v_present_count     INT;
  v_raw_pct           DECIMAL(5,2);
  v_ml_od_count       INT := 0;
  v_effective_present INT;
  v_effective_pct     DECIMAL(5,2);
  v_ml_od_applicable  BOOLEAN;
  v_eligibility       eligibility_status;
  v_rule              attendance_rules%ROWTYPE;
  v_min_pct           DECIMAL(5,2) := 65.00;
  v_risk_pct          DECIMAL(5,2) := 75.00;
BEGIN
  -- Fetch attendance rules
  SELECT * INTO v_rule
  FROM attendance_rules
  WHERE academic_year = p_academic_year
  LIMIT 1;

  IF FOUND THEN
    v_min_pct  := v_rule.detention_threshold;
    v_risk_pct := v_rule.risk_threshold;
  END IF;

  -- Count total classes and present sessions for this student/subject
  SELECT
    COUNT(*),
    COUNT(*) FILTER (WHERE status IN ('present', 'late', 'od'))
  INTO v_total_classes, v_present_count
  FROM attendance_raw
  WHERE student_id    = p_student_id
    AND subject_id    = p_subject_id
    AND academic_year = p_academic_year
    AND semester_number = p_semester_no;

  -- Calculate raw percentage
  IF v_total_classes = 0 THEN
    v_raw_pct := 0;
  ELSE
    v_raw_pct := ROUND((v_present_count::DECIMAL / v_total_classes) * 100, 2);
  END IF;

  -- ── ML/OD RULE ────────────────────────────────────────────
  -- Only apply ML/OD if raw_percentage >= minimum (e.g., 65%)
  IF v_raw_pct >= v_min_pct THEN
    v_ml_od_applicable := TRUE;

    -- Count approved ML/OD absences that overlap with actual absences
    SELECT COALESCE(SUM(
      LEAST(m.end_date, CURRENT_DATE) - GREATEST(m.start_date, '2000-01-01') + 1
    ), 0)
    INTO v_ml_od_count
    FROM ml_od m
    WHERE m.student_id = p_student_id
      AND m.status = 'approved'
      AND (m.subject_id = p_subject_id OR m.subject_id IS NULL)
      AND m.start_date <= CURRENT_DATE
      AND m.end_date   >= (
        SELECT MIN(date) FROM attendance_raw
        WHERE student_id = p_student_id AND subject_id = p_subject_id
          AND academic_year = p_academic_year
      );

    -- Cap ML/OD at rule maximum
    IF v_rule IS NOT NULL THEN
      v_ml_od_count := LEAST(v_ml_od_count, v_rule.ml_od_max_days);
    END IF;
  ELSE
    v_ml_od_applicable := FALSE;
    v_ml_od_count      := 0;
  END IF;

  -- Effective present = raw present + ML/OD adjustments
  v_effective_present := LEAST(v_present_count + v_ml_od_count, v_total_classes);

  IF v_total_classes = 0 THEN
    v_effective_pct := 0;
  ELSE
    v_effective_pct := ROUND((v_effective_present::DECIMAL / v_total_classes) * 100, 2);
  END IF;

  -- Determine eligibility
  IF v_effective_pct >= v_risk_pct THEN
    v_eligibility := 'eligible';
  ELSIF v_effective_pct >= v_min_pct THEN
    v_eligibility := 'at_risk';
  ELSE
    v_eligibility := 'detained';
  END IF;

  -- Upsert into attendance_effective
  INSERT INTO attendance_effective (
    student_id, subject_id, academic_year, semester_number,
    total_classes, present_count, raw_percentage,
    ml_od_count, effective_present_count, effective_percentage,
    is_ml_od_applicable, eligibility_status, last_calculated_at
  )
  VALUES (
    p_student_id, p_subject_id, p_academic_year, p_semester_no,
    v_total_classes, v_present_count, v_raw_pct,
    v_ml_od_count, v_effective_present, v_effective_pct,
    v_ml_od_applicable, v_eligibility, NOW()
  )
  ON CONFLICT (student_id, subject_id, academic_year, semester_number)
  DO UPDATE SET
    total_classes           = EXCLUDED.total_classes,
    present_count           = EXCLUDED.present_count,
    raw_percentage          = EXCLUDED.raw_percentage,
    ml_od_count             = EXCLUDED.ml_od_count,
    effective_present_count = EXCLUDED.effective_present_count,
    effective_percentage    = EXCLUDED.effective_percentage,
    is_ml_od_applicable     = EXCLUDED.is_ml_od_applicable,
    eligibility_status      = EXCLUDED.eligibility_status,
    last_calculated_at      = NOW();
END;
$$;

-- ─────────────────────────────────────────
-- TRIGGER: Recalculate after attendance_raw insert/update
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION trg_recalculate_attendance()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM calculate_effective_attendance(
    NEW.student_id,
    NEW.subject_id,
    NEW.academic_year,
    NEW.semester_number
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_attendance_raw_after_upsert
  AFTER INSERT OR UPDATE ON attendance_raw
  FOR EACH ROW EXECUTE FUNCTION trg_recalculate_attendance();

-- ─────────────────────────────────────────
-- TRIGGER: Recalculate after ML/OD approval status changes
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION trg_recalculate_on_ml_od()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_enrollment RECORD;
  v_academic_year TEXT;
  v_semester INT;
BEGIN
  -- Find the student's current enrollment to get academic_year and semester
  SELECT academic_year, semester_number INTO v_academic_year, v_semester
  FROM enrollments
  WHERE student_id = NEW.student_id
  ORDER BY enrolled_at DESC
  LIMIT 1;

  IF NEW.subject_id IS NOT NULL THEN
    PERFORM calculate_effective_attendance(
      NEW.student_id, NEW.subject_id, v_academic_year, v_semester
    );
  ELSE
    -- Apply to all enrolled subjects
    FOR v_enrollment IN
      SELECT subject_id FROM enrollments
      WHERE student_id = NEW.student_id
        AND academic_year = v_academic_year
    LOOP
      PERFORM calculate_effective_attendance(
        NEW.student_id, v_enrollment.subject_id, v_academic_year, v_semester
      );
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_ml_od_status_change
  AFTER UPDATE OF status ON ml_od
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'approved')
  EXECUTE FUNCTION trg_recalculate_on_ml_od();

-- ─────────────────────────────────────────
-- AUDIT LOG TRIGGER FACTORY
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION log_audit()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    INSERT INTO audit_logs(table_name, record_id, action, old_data, performed_by)
    VALUES(TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD), auth.uid());
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_logs(table_name, record_id, action, old_data, new_data, performed_by)
    VALUES(TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), auth.uid());
    RETURN NEW;
  ELSIF TG_OP = 'INSERT' THEN
    INSERT INTO audit_logs(table_name, record_id, action, new_data, performed_by)
    VALUES(TG_TABLE_NAME, NEW.id, 'INSERT', to_jsonb(NEW), auth.uid());
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;

-- Attach audit trigger to critical tables
CREATE TRIGGER audit_attendance_raw
  AFTER INSERT OR UPDATE OR DELETE ON attendance_raw
  FOR EACH ROW EXECUTE FUNCTION log_audit();

CREATE TRIGGER audit_ml_od
  AFTER INSERT OR UPDATE OR DELETE ON ml_od
  FOR EACH ROW EXECUTE FUNCTION log_audit();

CREATE TRIGGER audit_marks
  AFTER INSERT OR UPDATE OR DELETE ON marks
  FOR EACH ROW EXECUTE FUNCTION log_audit();

-- ─────────────────────────────────────────
-- HALL TICKET ELIGIBILITY AUTO-UPDATE
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_hall_ticket_eligibility(
  p_student_id    UUID,
  p_academic_year TEXT,
  p_semester_no   INT,
  p_exam_type     exam_type
)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_all_eligible BOOLEAN;
BEGIN
  -- Student is eligible only if all enrolled subjects >= minimum threshold
  SELECT BOOL_AND(ae.eligibility_status != 'detained')
  INTO v_all_eligible
  FROM attendance_effective ae
  WHERE ae.student_id      = p_student_id
    AND ae.academic_year   = p_academic_year
    AND ae.semester_number = p_semester_no;

  INSERT INTO hall_tickets(student_id, academic_year, semester_number, exam_type, is_eligible)
  VALUES(p_student_id, p_academic_year, p_semester_no, p_exam_type, COALESCE(v_all_eligible, FALSE))
  ON CONFLICT(student_id, academic_year, semester_number, exam_type)
  DO UPDATE SET is_eligible = EXCLUDED.is_eligible;
END;
$$;

-- ─────────────────────────────────────────
-- ANALYTICS VIEW: Low attendance students
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW vw_low_attendance AS
SELECT
  s.id                  AS student_id,
  p.full_name           AS student_name,
  s.register_no,
  d.name                AS department,
  s.current_semester,
  s.section,
  sub.name              AS subject_name,
  sub.code              AS subject_code,
  ae.raw_percentage,
  ae.effective_percentage,
  ae.ml_od_count,
  ae.is_ml_od_applicable,
  ae.eligibility_status,
  ae.academic_year,
  ae.last_calculated_at
FROM attendance_effective ae
JOIN students s   ON s.id = ae.student_id
JOIN profiles p   ON p.id = s.profile_id
JOIN subjects sub ON sub.id = ae.subject_id
LEFT JOIN departments d ON d.id = s.department_id
WHERE ae.effective_percentage < 75
ORDER BY ae.effective_percentage ASC;

-- ─────────────────────────────────────────
-- ANALYTICS VIEW: Student performa summary
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW vw_student_performa AS
SELECT
  s.id                  AS student_id,
  p.full_name           AS student_name,
  s.register_no,
  s.current_semester,
  s.section,
  s.batch,
  d.name                AS department,
  sub.id                AS subject_id,
  sub.name              AS subject_name,
  sub.code              AS subject_code,
  ae.total_classes,
  ae.present_count,
  ae.raw_percentage,
  ae.ml_od_count,
  ae.effective_present_count,
  ae.effective_percentage,
  ae.is_ml_od_applicable,
  ae.eligibility_status,
  ae.academic_year,
  ae.semester_number
FROM attendance_effective ae
JOIN students s   ON s.id = ae.student_id
JOIN profiles p   ON p.id = s.profile_id
JOIN subjects sub ON sub.id = ae.subject_id
LEFT JOIN departments d ON d.id = s.department_id;

-- ─────────────────────────────────────────
-- FUNCTION: Get student overall attendance
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_student_overall_attendance(
  p_student_id    UUID,
  p_academic_year TEXT,
  p_semester_no   INT
)
RETURNS TABLE (
  total_classes          BIGINT,
  present_count          BIGINT,
  raw_percentage         DECIMAL,
  effective_percentage   DECIMAL,
  subjects_at_risk       BIGINT,
  subjects_detained      BIGINT
) LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT
    SUM(ae.total_classes)::BIGINT,
    SUM(ae.present_count)::BIGINT,
    CASE WHEN SUM(ae.total_classes) = 0 THEN 0
         ELSE ROUND(SUM(ae.present_count)::DECIMAL / SUM(ae.total_classes) * 100, 2)
    END,
    CASE WHEN SUM(ae.total_classes) = 0 THEN 0
         ELSE ROUND(SUM(ae.effective_present_count)::DECIMAL / SUM(ae.total_classes) * 100, 2)
    END,
    COUNT(*) FILTER (WHERE ae.eligibility_status = 'at_risk')::BIGINT,
    COUNT(*) FILTER (WHERE ae.eligibility_status = 'detained')::BIGINT
  FROM attendance_effective ae
  WHERE ae.student_id    = p_student_id
    AND ae.academic_year = p_academic_year
    AND ae.semester_number = p_semester_no;
$$;
