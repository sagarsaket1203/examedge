-- ExamEdge Database Schema
-- PostgreSQL schema for NEET & JEE test platform
-- Created for Supabase

-- ============================================================
-- USERS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  exam_type VARCHAR(50) NOT NULL CHECK (exam_type IN ('NEET', 'JEE', 'BOTH')),
  role VARCHAR(50) NOT NULL DEFAULT 'student' CHECK (role IN ('admin', 'student')),
  total_points INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_total_points ON users(total_points DESC);

-- ============================================================
-- QUESTIONS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_type VARCHAR(50) NOT NULL CHECK (exam_type IN ('NEET', 'JEE', 'BOTH')),
  subject VARCHAR(100) NOT NULL,
  chapter VARCHAR(255) NOT NULL,
  difficulty VARCHAR(50) NOT NULL DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  question_text TEXT NOT NULL,
  option_a TEXT NOT NULL,
  option_b TEXT NOT NULL,
  option_c TEXT NOT NULL,
  option_d TEXT NOT NULL,
  correct VARCHAR(1) NOT NULL CHECK (correct IN ('A', 'B', 'C', 'D')),
  explanation TEXT,
  source VARCHAR(255),
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_questions_exam_type ON questions(exam_type);
CREATE INDEX idx_questions_subject ON questions(subject);
CREATE INDEX idx_questions_chapter ON questions(chapter);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);
CREATE INDEX idx_questions_created_by ON questions(created_by);

-- ============================================================
-- TESTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS tests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  exam_type VARCHAR(50) NOT NULL CHECK (exam_type IN ('NEET', 'JEE', 'BOTH')),
  test_type VARCHAR(50) NOT NULL CHECK (test_type IN ('chapter', 'subject', 'mixed', 'full_mock')),
  subject VARCHAR(100),
  chapter VARCHAR(255),
  duration_min INTEGER NOT NULL DEFAULT 45,
  total_marks INTEGER NOT NULL DEFAULT 180,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_tests_exam_type ON tests(exam_type);
CREATE INDEX idx_tests_test_type ON tests(test_type);
CREATE INDEX idx_tests_subject ON tests(subject);
CREATE INDEX idx_tests_created_by ON tests(created_by);

-- ============================================================
-- ATTEMPTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  test_id UUID NOT NULL REFERENCES tests(id) ON DELETE CASCADE,
  score INTEGER,
  total_marks INTEGER,
  accuracy_pct DECIMAL(5,2),
  time_taken_s INTEGER,
  points_earned INTEGER DEFAULT 0,
  submitted_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_attempts_user_id ON attempts(user_id);
CREATE INDEX idx_attempts_test_id ON attempts(test_id);
CREATE INDEX idx_attempts_submitted_at ON attempts(submitted_at DESC);
CREATE INDEX idx_attempts_accuracy ON attempts(accuracy_pct DESC);

-- ============================================================
-- ANSWERS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id UUID NOT NULL REFERENCES attempts(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  chosen VARCHAR(1) CHECK (chosen IS NULL OR chosen IN ('A', 'B', 'C', 'D')),
  is_correct BOOLEAN DEFAULT FALSE,
  is_marked BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_answers_attempt_id ON answers(attempt_id);
CREATE INDEX idx_answers_question_id ON answers(question_id);
CREATE INDEX idx_answers_is_correct ON answers(is_correct);

-- ============================================================
-- ANALYTICS VIEWS
-- ============================================================

-- User Performance Summary
CREATE OR REPLACE VIEW user_performance AS
SELECT
  u.id,
  u.name,
  u.email,
  u.exam_type,
  COUNT(DISTINCT a.id) as tests_taken,
  ROUND(AVG(CAST(a.accuracy_pct AS NUMERIC)), 2) as avg_accuracy,
  MAX(a.accuracy_pct) as best_accuracy,
  MIN(a.accuracy_pct) as worst_accuracy,
  u.total_points,
  u.created_at
FROM users u
LEFT JOIN attempts a ON u.id = a.user_id AND a.submitted_at IS NOT NULL
GROUP BY u.id, u.name, u.email, u.exam_type, u.total_points, u.created_at;

-- Subject-wise Accuracy
CREATE OR REPLACE VIEW subject_performance AS
SELECT
  u.id as user_id,
  u.name,
  q.subject,
  COUNT(DISTINCT a.id) as questions_attempted,
  SUM(CASE WHEN a.is_correct THEN 1 ELSE 0 END) as correct_answers,
  ROUND(100.0 * SUM(CASE WHEN a.is_correct THEN 1 ELSE 0 END) / COUNT(a.id), 2) as accuracy_pct
FROM users u
JOIN attempts att ON u.id = att.user_id AND att.submitted_at IS NOT NULL
JOIN answers a ON att.id = a.attempt_id
JOIN questions q ON a.question_id = q.id
GROUP BY u.id, u.name, q.subject;

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

-- Users: Public read, own write
CREATE POLICY "users_read_all" ON users FOR SELECT TO authenticated USING (true);
CREATE POLICY "users_update_own" ON users FOR UPDATE TO authenticated USING (auth.uid() = id);
CREATE POLICY "users_insert_self" ON users FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

-- Questions: Public read, admin only write/delete
CREATE POLICY "questions_read_all" ON questions FOR SELECT TO authenticated USING (true);
CREATE POLICY "questions_insert_admin" ON questions FOR INSERT TO authenticated
  WITH CHECK ((SELECT role FROM users WHERE id = auth.uid()) = 'admin');
CREATE POLICY "questions_delete_admin" ON questions FOR DELETE TO authenticated
  USING ((SELECT role FROM users WHERE id = auth.uid()) = 'admin');

-- Tests: Public read, admin only write/delete
CREATE POLICY "tests_read_all" ON tests FOR SELECT TO authenticated USING (true);
CREATE POLICY "tests_insert_admin" ON tests FOR INSERT TO authenticated
  WITH CHECK ((SELECT role FROM users WHERE id = auth.uid()) = 'admin');
CREATE POLICY "tests_delete_admin" ON tests FOR DELETE TO authenticated
  USING ((SELECT role FROM users WHERE id = auth.uid()) = 'admin');

-- Attempts: Users see only their own
CREATE POLICY "attempts_read_own" ON attempts FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "attempts_insert_own" ON attempts FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "attempts_update_own" ON attempts FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- Answers: Users see only their own
CREATE POLICY "answers_read_own" ON answers FOR SELECT TO authenticated
  USING (attempt_id IN (SELECT id FROM attempts WHERE user_id = auth.uid()));

-- ============================================================
-- SAMPLE DATA (for testing)
-- ============================================================

-- Sample Users
INSERT INTO users (email, name, exam_type, role) VALUES
  ('admin@examedge.com', 'Admin User', 'BOTH', 'admin'),
  ('student1@examedge.com', 'Rahul Sharma', 'NEET', 'student'),
  ('student2@examedge.com', 'Priya Verma', 'JEE', 'student'),
  ('student3@examedge.com', 'Amit Patel', 'NEET', 'student'),
  ('student4@examedge.com', 'Neha Singh', 'JEE', 'student')
ON CONFLICT (email) DO NOTHING;

-- Sample NEET Questions
INSERT INTO questions (exam_type, subject, chapter, difficulty, question_text, option_a, option_b, option_c, option_d, correct, explanation, source)
VALUES
  ('NEET', 'Biology', 'Cell Biology', 'easy',
   'Which organelle is known as the powerhouse of the cell?',
   'Mitochondria', 'Chloroplast', 'Nucleus', 'Ribosome',
   'A', 'Mitochondria produces ATP through cellular respiration.', 'NCERT Class 11 Ch 2'),
  ('NEET', 'Physics', 'Mechanics', 'medium',
   'What is the SI unit of acceleration?',
   'm/s', 'm/s²', 'km/h', 'cm/s²',
   'B', 'Acceleration is the rate of change of velocity, with SI unit m/s².', 'NCERT Class 11 Ch 3'),
  ('NEET', 'Chemistry', 'Atomic Structure', 'hard',
   'Which of the following has the highest electronegativity?',
   'Chlorine', 'Fluorine', 'Bromine', 'Iodine',
   'B', 'Fluorine has the highest electronegativity value (3.98) on Pauling scale.', 'NCERT Class 11 Ch 4');

-- Sample JEE Questions
INSERT INTO questions (exam_type, subject, chapter, difficulty, question_text, option_a, option_b, option_c, option_d, correct, explanation, source)
VALUES
  ('JEE', 'Maths', 'Calculus', 'medium',
   'The derivative of x² + 3x is:',
   '2x', '2x + 3', 'x + 3', '2x + 1',
   'B', 'Using power rule: d/dx(x²) = 2x and d/dx(3x) = 3', 'JEE Main PYQ'),
  ('JEE', 'Physics', 'Optics', 'hard',
   'The critical angle for total internal reflection at glass-air interface is:',
   '30°', '45°', '~42°', '60°',
   'C', 'Critical angle θc = sin⁻¹(1/μ) ≈ 42° for glass (μ ≈ 1.5)', 'JEE Advanced PYQ'),
  ('JEE', 'Chemistry', 'Coordination Chemistry', 'medium',
   'The oxidation state of Mn in KMnO₄ is:',
   '+5', '+6', '+7', '+4',
   'C', 'In permanganate, Mn is +7. K is +1, O is -2. (+1) + x + 4(-2) = 0, so x = +7', 'JEE Main PYQ');

-- Sample Tests
INSERT INTO tests (title, exam_type, test_type, subject, chapter, duration_min, total_marks)
VALUES
  ('NEET Biology - Cell Biology Chapter Test', 'NEET', 'chapter', 'Biology', 'Cell Biology', 30, 120),
  ('JEE Maths - Calculus Subject Test', 'JEE', 'subject', 'Maths', NULL, 45, 120),
  ('NEET Full Mock Exam', 'NEET', 'full_mock', NULL, NULL, 200, 720),
  ('JEE Main Full Mock Exam', 'JEE', 'full_mock', NULL, NULL, 180, 300)
ON CONFLICT DO NOTHING;

-- ============================================================
-- GRANTS (for Supabase Auth)
-- ============================================================

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
