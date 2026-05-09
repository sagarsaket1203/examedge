# ExamEdge Architecture

Complete system design, components, and data flow for the ExamEdge platform.

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────┐
│           Frontend (React + Vite)           │
│  ├─ Dashboard                               │
│  ├─ Test Interface                          │
│  ├─ Analytics                               │
│  ├─ Leaderboard                             │
│  └─ Admin Panel                             │
└────────────┬────────────────────────────────┘
             │ (Supabase JS Client)
             ▼
┌─────────────────────────────────────────────┐
│      Supabase (Backend-as-a-Service)        │
│  ├─ PostgreSQL Database                     │
│  ├─ Authentication (JWT)                    │
│  ├─ Real-time Subscriptions                 │
│  ├─ Row-Level Security (RLS)                │
│  └─ Serverless Functions (Functions)        │
└─────────────────────────────────────────────┘
```

---

## 📊 Database Schema

### Tables Overview

```
users
├─ id (UUID, PK)
├─ email (VARCHAR)
├─ name (VARCHAR)
├─ exam_type (NEET | JEE | BOTH)
├─ role (admin | student)
├─ total_points (INTEGER)
└─ timestamps

questions
├─ id (UUID, PK)
├─ exam_type
├─ subject
├─ chapter
├─ difficulty (easy | medium | hard)
├─ question_text
├─ options (A, B, C, D)
├─ correct (A-D)
├─ explanation
├─ source
├─ created_by (FK → users)
└─ timestamps

tests
├─ id (UUID, PK)
├─ title
├─ exam_type
├─ test_type (chapter | subject | mixed | full_mock)
├─ subject (optional filter)
├─ chapter (optional filter)
├─ duration_min
├─ total_marks
├─ created_by (FK → users)
└─ timestamps

attempts
├─ id (UUID, PK)
├─ user_id (FK → users)
├─ test_id (FK → tests)
├─ score
├─ accuracy_pct
├─ time_taken_s
├─ points_earned
├─ submitted_at
└─ timestamps

answers
├─ id (UUID, PK)
├─ attempt_id (FK → attempts)
├─ question_id (FK → questions)
├─ chosen (A-D or NULL)
├─ is_correct (BOOLEAN)
├─ is_marked (BOOLEAN)
└─ timestamps
```

### Relationships

```
users ─────┐
           ├─→ questions (created_by)
           ├─→ tests (created_by)
           └─→ attempts (user_id)
                 ├─→ tests (test_id)
                 └─→ answers (attempt_id)
                       └─→ questions (question_id)
```

---

## 🎨 Frontend Components

### Page Structure

```
App
├─ Auth
│  ├─ Login Page
│  └─ Sign Up Page
├─ Dashboard
│  ├─ Stats Cards (Tests, Accuracy, Points)
│  ├─ Student Performance Cards
│  └─ Recent Attempts Table
├─ Tests
│  ├─ Test List
│  ├─ Test Creator Modal
│  └─ Test Active (Full Screen)
│     ├─ Question Panel
│     ├─ Options (A-D)
│     ├─ Timer
│     └─ Question Palette
├─ Analytics
│  ├─ Overall Performance
│  ├─ Subject Accuracy Chart
│  ├─ Weak Topics Alert
│  └─ Test History
├─ Leaderboard
│  ├─ All-time Rankings
│  └─ Weekly Top Performer
└─ Admin
   ├─ Question Management
   ├─ User Management
   └─ Test Management
```

### Key Components

#### Dashboard Component
- Displays stats: total tests, questions, avg accuracy, users
- Shows each student's performance by subject
- Lists recent test attempts
- Highlights weak subjects

**Props:** `students`, `attempts`  
**State:** None (pure component)

#### TestInterface Component
- Full-screen test taking experience
- Question panel with options
- Timer display with urgency
- Question palette navigator
- Mark for review button

**Props:** `test`, `questions`  
**State:** `currentQuestion`, `answers`, `timeLeft`, `markedQuestions`

#### AnalyticsPage Component
- Subject-wise accuracy bars
- Weak topics below 60%
- Test history table
- Performance trends

**Props:** `user`, `attempts`  
**State:** Derived from props

#### LeaderboardPage Component
- Ranked user list with points
- Week-based statistics
- Achievement badges

**Props:** `users`, `attempts`  
**State:** `sortBy`, `timeRange`

---

## 🔄 Data Flow

### Test Taking Flow

```
User Opens Test
    ↓
Load Test Config + Questions
    ↓
Create Attempt Record
    ↓
Start Timer
    ↓
User Selects Answer → Save to state
    ↓
User Marks for Review
    ↓
User Navigates Questions
    ↓
User Submits Test
    ↓
Calculate Score
    ├─ Correct: +4
    ├─ Incorrect: -1
    └─ Unanswered: 0
    ↓
Save Attempt Record
    ↓
Save All Answers
    ↓
Update User Points
    ↓
Show Results
    ↓
Redirect to Dashboard
```

### Analytics Computation

```
Get All Attempts for User
    ↓
For Each Attempt:
  ├─ Calculate Accuracy % = (Correct Answers / Total Qs) × 100
  └─ Get Subject from Question
    ↓
Group Accuracy by Subject
    ↓
Identify Subjects < 60% as Weak
    ↓
Generate Visualizations
```

---

## 🔐 Security Features

### Row-Level Security (RLS) Policies

**Users Table:**
- ✅ Anyone can view all users
- ✅ Users can only update their own profile

**Questions Table:**
- ✅ Anyone can view questions
- ✅ Only admins can create/edit questions

**Tests Table:**
- ✅ Anyone can view tests
- ✅ Only admins can create tests

**Attempts Table:**
- ✅ Users can only view/create their own attempts

**Answers Table:**
- ✅ Users can only view answers from their own attempts

### Environment Variables

```env
VITE_SUPABASE_URL          # Public, safe to expose
VITE_SUPABASE_ANON_KEY     # Public key, limited by RLS
(Never use Service Role Key in frontend)
```

### Best Practices

- ✅ All sensitive keys in `.env` files (not in code)
- ✅ RLS policies enforce data access control
- ✅ JWT tokens for session management
- ✅ SQL injection prevented by Supabase client
- ✅ CORS configured on Supabase

---

## 🚀 API Endpoints (Via Supabase)

### Database Queries

All queries through Supabase JS client:

```javascript
// Get users
const { data } = await supabase.from('users').select('*');

// Get questions for a test
const { data } = await supabase
  .from('questions')
  .select('*')
  .eq('exam_type', 'NEET')
  .eq('subject', 'Biology');

// Create attempt
const { data } = await supabase
  .from('attempts')
  .insert({ user_id, test_id })
  .select();

// Save answers
await supabase
  .from('answers')
  .insert(answerArray);

// Get user performance
const { data } = await supabase
  .from('user_performance')  // View
  .select('*')
  .eq('id', user_id);
```

---

## 📈 Performance Considerations

### Database Optimization

- ✅ Indexes on frequently queried columns
- ✅ Views for complex aggregations
- ✅ Pagination for large result sets
- ✅ Composite indexes for multi-column filters

### Frontend Optimization

- ✅ React lazy loading for route splitting
- ✅ Memoization for expensive computations
- ✅ Real-time subscriptions (future)
- ✅ Local state caching

### Limits (Supabase Free Tier)

- 500 MB database storage
- 5 GB monthly bandwidth
- 1 GB file storage
- 50,000 auth users

---

## 📱 State Management

### Global State (Context API)

```javascript
AuthContext
├─ user (current logged-in user)
├─ isLoading
└─ error

TestContext
├─ activeTest
├─ currentQuestion
├─ answers
├─ timeLeft
└─ testStartTime
```

### Local State (useState)

- Form inputs
- Modal visibility
- UI toggles
- Filter selections

---

## 🎯 Feature Flow

### Adding a Question (Admin)

```
Admin Form
    ↓
Fill Question Details
    ├─ Exam Type
    ├─ Subject
    ├─ Chapter
    ├─ Question Text
    ├─ Options A-D
    ├─ Correct Answer
    ├─ Difficulty
    └─ Explanation (optional)
    ↓
Validate Input
    ↓
Insert into DB
    ↓
Show Success Toast
    ↓
Refresh Question List
```

### Taking a Test (Student)

```
Student Clicks "Start Test"
    ↓
Load Test Config
    ↓
Fetch Matching Questions
    ↓
Create Attempt Record
    ↓
Start Timer
    ↓
Display Question
    ↓
Student Selects Answer
    ├─ Save to state
    └─ Mark for review (optional)
    ↓
Navigate to Next Question
    ↓
[Repeat until last question]
    ↓
Submit Test
    ↓
Calculate Score
    ↓
Save Results
    ↓
Show Results Page
    ↓
Redirect to Dashboard
```

---

## 🔄 Future Enhancements

### Phase 2
- [ ] Email notifications
- [ ] CSV import for questions
- [ ] Discussion forum
- [ ] Solution video links
- [ ] Performance prediction

### Phase 3
- [ ] Mobile app (React Native)
- [ ] AI difficulty adjustment
- [ ] Study schedule planner
- [ ] Collaboration features
- [ ] Payment integration

---

## 📚 Component Dependencies

```
App
├─ requires: AuthContext
├─ requires: Router (React Router)
└─ provides: Layout

Dashboard
├─ requires: users, attempts
├─ uses: Stats Card, Student Card, Table

TestInterface
├─ requires: test, questions
├─ state: answers, timer
└─ calls: submitTest()

Analytics
├─ requires: user, attempts
├─ uses: BarChart (Recharts)
└─ computes: accuracy, weak topics

Admin
├─ requires: admin role
├─ uses: Form Modal
└─ calls: insert/update/delete
```

---

**See database/schema.sql for complete database documentation.**
