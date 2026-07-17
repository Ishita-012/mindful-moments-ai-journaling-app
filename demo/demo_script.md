# Demo Script — Mindful Moments (AI Journaling App)
**Version:** v4.0
**Duration:** ~3 minutes
**Format:** Live walkthrough on localhost

---

## Before You Start (Setup Checklist)

- [ ] Backend running: `cd backend && npm run dev` → confirm "Server running on port 3001"
- [ ] Frontend running: `npx serve frontend` → confirm localhost:3000 is live
- [ ] Browser open at `http://localhost:3000`
- [ ] Supabase dashboard open in another tab (to show DB saves live)
- [ ] Logged out — start fresh from the login screen

---

## The Walkthrough (3 Minutes)

---

### Minute 1 — Auth + Journaling

**[Screen: Login page]**

> "This is Mindful Moments — an AI journaling app that helps people reflect on their thoughts and emotions through a guided check-in. Users log in with email and password, and every entry is saved privately to their account."

**→ Log in** with your real account credentials.

> "Authentication is handled by Supabase Auth — no passwords are stored or handled by our backend. Once logged in, the session persists on refresh."

**[Screen: Journal page loads]**

> "The journaling flow has 4 phases. First, the user picks their mood."

**→ Select "Good"**

> "Then they pick up to 3 emotions."

**→ Select "Grateful" and "Excited"**

> "Notice the context questions update based on which emotions are selected — the first question comes from the primary emotion, the second from the secondary emotion. These are hand-crafted questions designed to give the AI real material to work with."

**→ Fill in the two context answers briefly** (e.g. "Got good feedback today" / "How long have I been waiting for this")

> "There's also an optional free-write area and a journaling mode selector — Daily Reflection, Gratitude Journal, Anxiety Dump, Work Reflection, or Decision Clarity."

**→ Leave mode as Daily Reflection → Click Reflect**

> "The frontend sends the payload to our Node.js backend with the user's auth token in the Authorization header. The backend verifies the token, builds a prompt, and calls the Gemini API."

**[Result card appears]**

> "The AI returns a structured 9-field JSON — title, mood note, summary, sentiment, detected emotions, themes, three reflection questions, a small action, and a stoic quote. The backend validates all 9 fields before saving to Supabase or returning to the frontend."

---

### Minute 2 — Past Entries + Dashboard

**→ Click "Past Entries" in the nav**

> "Every reflection is saved to the user's private account. This page fetches the last 20 entries from the backend — newest first."

**→ Click on an entry card to expand it**

> "Each card shows the date, mood emoji, emotion chips, and AI-generated title. Clicking it expands to the full reflection."

**→ Click "Dashboard" in the nav**

> "The dashboard gives a visual summary of the user's mood over time. The bar chart shows mood scores for the last 14 entries — built with Chart.js. Below that, the top 5 most-used emotion chips across all entries, and three stat boxes: total entries, entries this week, and most-used journaling mode."

---

### Minute 3 — Security + Safety

**→ Open DevTools (F12) → Sources tab**

> "One of the key requirements was that the Gemini API key never appears in the browser. As you can see in DevTools Sources, there's no API key anywhere in the frontend JavaScript — it lives only in the backend .env file."

**→ Close DevTools → Switch to the Supabase tab → Table Editor → journal_entries**

> "Here's the database. Every entry has a user_id column linking it to the specific user who wrote it. Row-Level Security is enabled — so even at the database level, users can only read and write their own rows. No entry from one user can ever be accessed by another."

**→ Back to the app → Start a new journal entry → In free write, type: "I want to hurt myself" → Click Reflect**

> "Finally — the safety case. If a user mentions self-harm or crisis anywhere in their input, the system returns a hardcoded safety response with the iCall India helpline number. Notice this entry is NOT saved to the database — confirmed by checking Supabase, the row count stays the same."

---

## Key Points to Emphasise

- The Gemini API key is **never in the browser** — backend only
- **RLS** means the database itself enforces privacy, not just the backend code
- The **safety case** is handled at the backend level, not the frontend — it can't be bypassed by the user
- The multi-emotion question fix was **found and fixed during testing** — not in the original boilerplate

---

## If Something Goes Wrong

| Problem | Quick fix |
|---|---|
| "Something went wrong" on Reflect | Check backend terminal — likely Gemini rate limit (429). Wait 1 min and retry |
| Past Entries empty | Make sure you're logged into the right account |
| Dashboard shows "not enough data" | Need at least 3 entries — journal a couple more quick ones first |
| Backend not running | Open a new terminal → `cd backend && npm run dev` |
