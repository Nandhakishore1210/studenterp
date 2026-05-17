-- ============================================================
-- Student+ ERP — Universities table + schema updates
-- ============================================================

-- Universities table
CREATE TABLE IF NOT EXISTS universities (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name             TEXT UNIQUE NOT NULL,
  code             TEXT UNIQUE NOT NULL,
  city             TEXT,
  established_year INT,
  logo_url         TEXT,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE universities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "universities_read_all" ON universities FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "universities_write_admin" ON universities FOR ALL USING (is_admin());

-- Add university_id to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS university_id UUID REFERENCES universities(id);

-- Drop old unique constraints on departments (allow same code across universities)
ALTER TABLE departments DROP CONSTRAINT IF EXISTS departments_name_key;
ALTER TABLE departments DROP CONSTRAINT IF EXISTS departments_code_key;
ALTER TABLE departments ADD COLUMN IF NOT EXISTS university_id UUID REFERENCES universities(id);
ALTER TABLE departments ADD CONSTRAINT IF NOT EXISTS departments_code_uni_unique UNIQUE (code, university_id);

-- Drop old unique constraint on subjects code (allow same code across universities)
ALTER TABLE subjects DROP CONSTRAINT IF EXISTS subjects_code_key;
ALTER TABLE subjects ADD CONSTRAINT IF NOT EXISTS subjects_code_dept_unique UNIQUE (code, department_id);
