# Technical Specification Document
## Mindful Moments — AI Journaling App (v4.0)

**Author:** Ishita
**Date:** July 2026
**Status:** MVP Complete

---

## 1. Project Overview

Mindful Moments is a full-stack AI-powered journaling web app. Users log in with email and password, complete a guided 4-phase emotional check-in, and receive a personalised AI reflection. Every entry is saved privately to their account. Users can scroll their past entries and view a mood dashboard.

This is not a therapy app. It is a private journaling companion powered by a large language model.

---

## 2. Tech Stack

| Layer | Technology | Why |
|---|---|---|
| Frontend | HTML + CSS + Vanilla JavaScript | Simple, no build step needed for MVP |
| Backend | Node.js + Express | Lightweight, easy to set up REST API |
| Database | Supabase (Postgres) | Managed DB + Auth in one service, free tier available |
| Authentication | Supabase Auth | Handles signup, login, sessions, email confirmation out of the box |
| AI | Google Gemini 2.5 Flash (via @google/genai SDK) | Switched from OpenAI GPT-4o mini per intern task — free tier available |
| Frontend server | npx serve | Simple local static file server for development |
| Package manager | npm | Standard Node.js package manager |

**Note:** The original PRD specified OpenAI GPT-4o mini. This was swapped to Google Gemini 2.5 Flash during the intern build. All other architecture decisions follow the PRD exactly.

---

## 3. Architecture Overview

```
Browser (Frontend)
      |
      | HTTP requests with Auth token
      |
Node.js + Express (Backend — port 3001)
      |              |
      |              | Gemini API call (POST /api/reflect only)
      |              |
      |         Google Gemini 2.5 Flash
      |
Supabase
  ├── Auth (verify tokens, manage users)
  └── Postgres DB (store journal entries)
```

**Data flow summary:**
- Frontend → Backend (with auth token) → Gemini → Backend → Supabase → Frontend
- Frontend → Backend (with auth token) → Supabase → Frontend (for entries + dashboard)

---

## 4. File Structure

```
mindful-moments/
├── frontend/
│   ├── index.html        ← Login / signup screen
│   ├── journal.html      ← 4-phase journaling flow
│   ├── entries.html      ← Past entries page
│   ├── dashboard.html    ← Mood dashboard
│   ├── style.css         ← All shared styles
│   ├── auth.js           ← Supabase Auth logic (login, signup, logout)
│   ├── app.js            ← Journaling flow logic + POST /api/reflect call
│   ├── entries.js        ← Fetches + renders past entries
│   └── dashboard.js      ← Fetches dashboard data + renders Chart.js
├── backend/
│   ├── server.js         ← Express server with 3 routes + auth middleware
│   ├── package.json      ← Dependencies
│   ├── .env              ← Secret keys (never committed to git)
│   └── .env.example      ← Template for environment variables
├── database/
│   ├── schema.sql        ← Creates journal_entries table
│   └── rls_policies.sql  ← Enables Row Level Security
├── prompts/
│   └── system_prompt.txt ← AI system prompt (loaded into server.js)
├── docs/
│   ├── test_results.md   ← All 14 test case results
│   ├── technical_spec.md ← This document
│   └── user_manual.md    ← End user guide
└── demo/
    └── demo_script.md    ← 3-minute walkthrough script
```

---

## 5. Environment Variables

All secrets live in `backend/.env`. This file is never committed to git.

```env
SUPABASE_URL=https://yourproject.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
GEMINI_API_KEY=your_gemini_api_key
PORT=3001
```

**Important:**
- Use the **service_role** key in the backend (not the anon key) — it allows the backend to verify auth tokens
- Use the **anon/public** key in the frontend JS files — it's safe to expose
- The Gemini API key must **never** appear in any frontend file

---

## 6. Database Schema

One table: `journal_entries`

```sql
CREATE TABLE journal_entries (
  id                UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id           UUID        REFERENCES auth.users(id) ON DELETE CASCADE,
  mood              TEXT,
  emotions          TEXT[],
  context_answer_1  TEXT,
  context_answer_2  TEXT,
  free_write        TEXT,
  mode              TEXT,
  ai_response_json  JSONB,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);
```

**Key columns:**
- `user_id` — links every entry to a specific authenticated user
- `ai_response_json` — stores the full 9-field Gemini response as JSONB
- `emotions` — stored as a Postgres array (TEXT[])

**Row Level Security:** Enabled. Users can only SELECT, INSERT, or DELETE their own rows. Enforced at the database level as a safety net independent of backend logic.

---

## 7. Backend API Endpoints

All routes require a valid Supabase session token in the `Authorization: Bearer <token>` header. Requests without a valid token return `401 Unauthorized`.

### POST /api/reflect

Receives a journal entry, calls Gemini, validates the response, saves to Supabase, returns the AI reflection.

**Request body:**
```json
{
  "mood": "low",
  "emotions": ["Anxious", "Overwhelmed"],
  "contextAnswer1": "Work pressure",
  "contextAnswer2": "I feel behind",
  "freeWrite": "I don't know where to start",
  "mode": "Anxiety Dump"
}
```

**Response (success):**
```json
{
  "title": "Navigating Uncertainty's Weight",
  "mood_note": "It sounds like you're carrying a heavy load right now.",
  "summary": "You're feeling stuck...",
  "sentiment": "negative",
  "emotions": ["anxious", "overwhelmed", "unsettled", "vulnerable"],
  "themes": ["uncertainty", "emotional overwhelm", "self-awareness"],
  "reflection_questions": ["...", "...", "..."],
  "small_action": "Take a few slow, deep breaths.",
  "stoic_quote": "You have power over your mind — not outside events. — Marcus Aurelius"
}
```

**Safety case:** If user mentions self-harm or crisis, returns a hardcoded safety JSON with iCall India helpline (9152987821). Entry is NOT saved to Supabase in this case.

**Response (error):**
```json
{ "error": true, "message": "Failed to generate reflection. Please try again." }
```

---

### GET /api/entries

Returns the logged-in user's last 20 journal entries, newest first.

**Response:**
```json
[
  {
    "id": "uuid",
    "mood": "good",
    "emotions": ["Grateful", "Excited"],
    "mode": "Daily Reflection",
    "ai_response_json": { ...9 fields... },
    "created_at": "2026-06-30T10:30:00Z"
  }
]
```

---

### GET /api/dashboard

Returns mood timeline, top emotions, and stats for the logged-in user.

**Response:**
```json
{
  "moodTimeline": [
    { "date": "Jun 30", "moodScore": 4, "moodLabel": "good" }
  ],
  "topEmotions": [
    { "emotion": "Anxious", "count": 3 }
  ],
  "stats": {
    "totalEntries": 6,
    "entriesThisWeek": 6,
    "mostUsedMode": "Daily Reflection"
  }
}
```

---

## 8. Auth Flow

1. User signs up → Supabase creates account, sends confirmation email
2. User confirms email → account activated
3. User logs in → Supabase returns a session with an `access_token`
4. Frontend stores token in browser (Supabase handles this automatically)
5. Every API call includes `Authorization: Bearer <access_token>` header
6. Backend calls `supabase.auth.getUser(token)` to verify and extract `user.id`
7. `user.id` is used to filter all DB queries to that user's data only
8. On logout → `supabase.auth.signOut()` clears the session → redirect to login

---

## 9. AI Integration

**Model:** `gemini-2.5-flash`
**SDK:** `@google/genai`
**Max output tokens:** 2000

**System prompt:** Loaded from `prompts/system_prompt.txt` into `server.js`. Instructs Gemini to act as a compassionate journaling companion, return only valid JSON with 9 specific fields, and never diagnose mental health conditions.

**JSON validation:** After Gemini responds, the backend:
1. Strips markdown code fences (Gemini sometimes wraps JSON in ` ```json ``` ` despite being told not to)
2. Parses with `JSON.parse()`
3. Validates all 9 required fields exist
4. Throws an error if any field is missing

**Known quirk:** Gemini occasionally omits attribution on the `stoic_quote` field despite the system prompt requesting it. This is LLM output variability — not a code bug.

**Free tier limits:** ~20 requests/day on `gemini-2.5-flash` free tier (as observed during testing). Sufficient for demo and light personal use.

---

## 10. How to Run Locally

**Prerequisites:**
- Node.js v24+ (LTS)
- A Supabase project with `schema.sql` and `rls_policies.sql` run
- A Gemini API key from [aistudio.google.com](https://aistudio.google.com)

**Steps:**

```bash
# 1. Install backend dependencies
cd backend
npm install

# 2. Set up environment variables
cp .env.example .env
# Fill in SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, GEMINI_API_KEY

# 3. Replace YOUR_SUPABASE_URL and YOUR_SUPABASE_ANON_KEY
# in frontend/auth.js, app.js, entries.js, dashboard.js

# 4. Start the backend
npm run dev
# → Server running on port 3001

# 5. In a new terminal, serve the frontend
npx serve frontend
# → Open http://localhost:3000
```

---

## 11. Security Considerations

| Rule | Implementation |
|---|---|
| Gemini API key never in frontend | Stored only in `backend/.env` |
| Service role key never in frontend | Stored only in `backend/.env` |
| All routes require auth | `requireAuth` middleware on all 3 routes |
| RLS enabled | Database-level row filtering as safety net |
| `.env` in `.gitignore` | Confirmed during setup |
| Email confirmation required | Enabled in Supabase Auth settings |
| Safety case not saved | Backend checks title field, returns early without DB insert |

---

## 12. Known Issues and Limitations

| Issue | Severity | Notes |
|---|---|---|
| `stoic_quote` attribution inconsistent | Low | LLM variability, system prompt already requests it |
| Free tier Gemini quota (20 req/day) | Medium | Sufficient for demo, upgrade API plan for production |
| No session expiry handling in frontend | Low | Documented in PRD Section 13, not in official test cases |
| Desktop only — no mobile responsiveness | Low | Out of scope per PRD (P2) |
| Context questions use first 2 emotions only (3rd ignored for questions) | Low | By design — UI shows exactly 2 questions |
