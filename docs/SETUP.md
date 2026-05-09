# ExamEdge Setup Guide

Complete step-by-step guide to set up ExamEdge locally and prepare for deployment.

---

## 📋 Prerequisites

Before starting, ensure you have:

- **Node.js 18+** — [Download here](https://nodejs.org)
- **Git** — [Download here](https://git-scm.com)
- **Supabase Account** — [Sign up for free](https://supabase.com)
- **GitHub Account** — Already have it (sagarsaket1203)

---

## 🚀 Step-by-Step Setup

### Step 1: Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and log in
2. Click **"New Project"**
3. Fill in the details:
   - **Project name:** `examedge` (or anything)
   - **Database password:** Create a strong password (save it!)
   - **Region:** Choose closest to your location (e.g., `us-east-1` or `ap-south-1`)
   - **Pricing Plan:** Free tier (sufficient for 5 users)
4. Wait for project to initialize (~2 minutes)
5. Once ready, you'll see the **Project Settings** page

### Step 2: Get Your Supabase Credentials

1. In Supabase dashboard, go to **Settings** → **API**
2. Copy these values (you'll need them in Step 5):
   - **Project URL** (e.g., `https://xxxxxx.supabase.co`)
   - **Anon Key** (public key, safe to expose in frontend)
   
**⚠️ IMPORTANT:** Never commit these keys to Git! Use `.env` files.

### Step 3: Set Up the Database

1. In Supabase, go to **SQL Editor**
2. Click **"New Query"**
3. Copy the entire content from [`database/schema.sql`](../database/schema.sql)
4. Paste it into the SQL Editor
5. Click **"Run"**
6. Wait for execution to complete (should see "Success" messages)

**What was created:**
- ✅ `users` table (admin + students)
- ✅ `questions` table (NEET/JEE questions)
- ✅ `tests` table (test configurations)
- ✅ `attempts` table (test submissions)
- ✅ `answers` table (per-question responses)
- ✅ RLS (Row-Level Security) policies
- ✅ Sample data for testing

### Step 4: Clone the Repository

```bash
# Clone the repo
git clone https://github.com/sagarsaket1203/examedge.git

# Navigate to project
cd examedge

# Navigate to frontend
cd frontend
```

### Step 5: Set Up Environment Variables

1. In the `frontend/` directory, rename `.env.example` to `.env.local`:
   ```bash
   cp .env.example .env.local
   ```

2. Open `frontend/.env.local` and fill in your Supabase credentials:
   ```
   VITE_SUPABASE_URL=https://xxxxxx.supabase.co
   VITE_SUPABASE_ANON_KEY=your_anon_key_here
   ```

3. Save the file

**⚠️ Important:** Never commit `.env.local` to Git (it's in .gitignore)

### Step 6: Install Dependencies

```bash
# Make sure you're in the frontend/ directory
cd examedge/frontend

# Install npm packages
npm install
```

This will install:
- React 18
- Vite
- Supabase JS Client
- Tailwind CSS
- Recharts (for charts)
- And other dependencies

### Step 7: Start the Development Server

```bash
# Start dev server
npm run dev
```

You should see output like:
```
➜  Local:   http://localhost:5173/
```

### Step 8: Access the App

1. Open your browser
2. Go to: **http://localhost:5173**
3. You should see the ExamEdge dashboard

**Test Credentials (from sample data):**
- Email: `admin@examedge.com` | Role: Admin
- Email: `student1@examedge.com` | Role: Student (NEET)
- Email: `student2@examedge.com` | Role: Student (JEE)

---

## 🧪 Testing the App

### Add a Question (Admin)

1. Switch to admin user
2. Go to **Manage Questions** section
3. Click **"+ Add question"**
4. Fill in sample question
5. Click **"Save question"**

### Create a Test

1. Go to **Tests**
2. Click **"+ Create test"**
3. Fill in test details
4. Click **"Create test"**

### Take a Test (Student)

1. Switch to a student user
2. Go to **Take a test**
3. Click **"Start →"** on any test
4. Answer questions
5. Click **"Submit test"**
6. View results on dashboard

### Check Analytics

1. Switch to a student
2. Go to **Analytics**
3. See subject accuracy and weak topics

---

## 📁 Project Structure (Frontend)

```
frontend/
├── src/
│   ├── components/          # Reusable UI components
│   ├── pages/              # Page components
│   ├── hooks/              # Custom React hooks
│   ├── context/            # Auth/state context
│   ├── utils/              # Helper functions
│   ├── App.jsx             # Main app component
│   └── main.jsx            # React entry point
├── public/                 # Static assets
├── .env.example            # Environment variables template
├── .env.local              # Your actual env vars (local only)
├── vite.config.js          # Vite configuration
├── package.json            # Dependencies
└── index.html              # HTML entry point
```

---

## 🐛 Troubleshooting

### Issue: "Cannot find module 'supabase'"
**Solution:**
```bash
cd frontend
npm install
npm run dev
```

### Issue: "VITE_SUPABASE_URL is undefined"
**Solution:** Make sure `.env.local` exists and has correct values:
```bash
# Check file exists
ls -la .env.local

# File should contain:
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=your_key_here
```

### Issue: "Port 5173 already in use"
**Solution:**
```bash
# Kill process on port 5173 (Unix/Mac)
lsof -i :5173 | grep LISTEN | awk '{print $2}' | xargs kill -9

# Or use different port
npm run dev -- --port 3000
```

### Issue: Database queries not working
**Solution:** Check Supabase RLS policies are enabled:
1. Go to Supabase Dashboard
2. Go to **Authentication** → **Policies**
3. Ensure policies are active (should be from schema.sql)

---

## 🚀 Next Steps

### Local Development

1. **Start coding:** Edit files in `src/` directory
2. **Hot reload:** Changes auto-reload in browser
3. **Debug:** Open DevTools (F12) to see console

### Before Deployment

1. **Security:** Remove hardcoded secrets ✅ (using .env)
2. **Testing:** Test with your brothers
3. **Documentation:** Update README with features

### Deploy to Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy from root directory
vercel

# Follow prompts
```

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed deployment guide (coming soon).

---

## 📚 Additional Resources

- **Supabase Docs:** https://supabase.com/docs
- **React Docs:** https://react.dev
- **Vite Docs:** https://vitejs.dev
- **Tailwind CSS:** https://tailwindcss.com

---

## ❓ Need Help?

1. Check the **[ARCHITECTURE.md](./ARCHITECTURE.md)** for system design
2. Open an **[Issue on GitHub](https://github.com/sagarsaket1203/examedge/issues)**
3. Join the discussion in GitHub Discussions

---

**You're all set! 🎉 Start the dev server with `npm run dev` and explore ExamEdge!**
