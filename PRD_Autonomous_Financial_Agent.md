# PRD — Autonomous Financial Management Agent
**CSI Origin 2026 — Problem Statement 1**
**Scope:** Hackathon MVP (36–48 hr build)

---

## 1. Problem recap

Variable-income users (gig workers, freelancers) have financial data fragmented across bank transactions, SMS alerts, email receipts, and bills. Existing apps are reactive dashboards that require the user to interpret their own risk. We're building an agent that maintains an evolving model of the user's financial state and proactively surfaces explainable risks/opportunities — not another tracker.

## 2. Goals (hackathon scope)

- Ingest financial signals from **SMS** (existing parser) and **Gmail** (OAuth, parsed receipts/bills/statements).
- Deduplicate overlapping signals via fingerprinting.
- Maintain a **causal graph** of financial state in **Postgres** (income, obligations, goals, buffers) with confidence tags.
- Detect two kinds of triggers: **cascade risk** (graph propagation) and **behavioral anomaly** (deviation from baseline).
- Run all triggers through an **intervention gate** that decides what's worth surfacing.
- Use an **LLM reasoning agent** to explain surfaced insights in plain language, tied to the user's stated risk tolerance.
- Ship a **Flutter mobile app**: OAuth onboarding, an insight feed, and a lightweight graph/state view.

## 3. Non-goals (explicitly out of scope for the 48hr build)

- Real bank account integration (Plaid-equivalent) — out of scope; SMS + Gmail is the data surface.
- Investment account tracking / portfolio management.
- Multi-user / multi-account households.
- Production-grade auth, encryption at rest, compliance (PCI/RBI norms) — demo-grade only, called out explicitly to judges as a known gap.
- A trained ML model — anomaly detection is a statistical baseline (percentile/z-score), described honestly as "ML" in the sense of a learned baseline, not a trained neural net.

## 4. Demo persona

A single seeded gig-worker user with 2–3 months of synthetic + Gmail-derived transaction history: irregular income deposits, a rent obligation, a recurring SIP, and a savings goal. The demo narrative: a delayed payment triggers a cascade warning before it becomes a missed rent payment.

## 5. Data sources

| Source | Method | Notes |
|---|---|---|
| SMS | Existing parser algorithm | Already built — reuse as-is, feed output into the ingestion pipeline's common event schema |
| Gmail | Google OAuth (read-only Gmail scope) + email parser | New for this build — parse receipts, bill notifications, bank e-statements from inbox |
| Manual entry | Simple form | Fallback for anything the parsers miss, keeps demo controllable |

**Gmail OAuth flow (build note):** `gmail.readonly` scope only. Server-side token exchange, store refresh token encrypted. Poll or use Gmail push notifications (webhook) if time allows — polling is the safe fallback for a hackathon.

## 6. System architecture

```
Data sources (SMS parser, Gmail OAuth parser)
        │
        ▼
Ingestion & fingerprinting layer  →  normalize + hash + dedupe
        │
        ▼
State layer (Postgres)  →  causal graph (nodes/edges) + confidence tags
        │
        ▼
Intelligence layer  →  anomaly baseline (stats) + LLM reasoning agent (Claude API)
        │
        ▼
Intervention gate  →  severity × confidence × urgency scoring
        │
        ▼
Insight feed  →  Flutter mobile app
```

## 7. Data model (Postgres)

Graph modeled as adjacency-list tables inside Postgres — no separate graph DB (see rationale in section 12).

```sql
-- Core financial state nodes
CREATE TABLE nodes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  type TEXT NOT NULL,              -- 'income_source' | 'obligation' | 'goal' | 'buffer'
  label TEXT NOT NULL,
  value NUMERIC,                   -- amount, or NULL for non-numeric nodes
  confidence TEXT NOT NULL,        -- 'confirmed' | 'inferred' | 'predicted'
  metadata JSONB,                  -- cadence, due dates, category
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Relationships between nodes (the "causal graph")
CREATE TABLE edges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id UUID REFERENCES nodes(id),
  target_id UUID REFERENCES nodes(id),
  relation TEXT NOT NULL,          -- 'funds' | 'competes_with' | 'buffers_against'
  weight NUMERIC DEFAULT 1.0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Raw ingested events, pre-fingerprint
CREATE TABLE raw_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  source TEXT NOT NULL,            -- 'sms' | 'gmail' | 'manual'
  raw_payload JSONB,
  fingerprint TEXT,                -- hash of normalized (amount_bucket, merchant, time_window)
  matched_event_id UUID,           -- self-ref if merged into an existing fingerprint
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Gate output
CREATE TABLE insights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  trigger_type TEXT NOT NULL,      -- 'cascade' | 'anomaly'
  severity NUMERIC,
  confidence NUMERIC,
  urgency NUMERIC,
  gate_score NUMERIC,
  status TEXT NOT NULL,            -- 'surfaced' | 'suppressed'
  explanation TEXT,                -- LLM-generated narrative
  graph_path JSONB,                -- the node/edge path that triggered it, for the "why" view
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gmail_refresh_token TEXT,
  risk_tolerance TEXT,             -- 'low' | 'medium' | 'high', user-set
  created_at TIMESTAMPTZ DEFAULT now()
);
```

**Cascade propagation** (finding what a change affects downstream) is a recursive CTE over `edges`:

```sql
WITH RECURSIVE cascade AS (
  SELECT id, source_id, target_id, relation, weight, 1 AS depth
  FROM edges WHERE source_id = $1
  UNION ALL
  SELECT e.id, e.source_id, e.target_id, e.relation, e.weight, c.depth + 1
  FROM edges e JOIN cascade c ON e.source_id = c.target_id
  WHERE c.depth < 5
)
SELECT * FROM cascade;
```

## 8. Feature breakdown

### 8.1 Ingestion & fingerprinting
- SMS parser → common event schema (existing, wire it in).
- Gmail parser: OAuth → fetch recent messages → regex/LLM-assisted extraction of amount, merchant, date → common event schema.
- Fingerprint = hash of (amount bucket, normalized merchant, ±2 day window). Match against recent unresolved fingerprints before inserting a new node — merge and upgrade confidence instead of duplicating.

### 8.2 State layer
- Each new confirmed event updates or creates a node.
- Recurring pattern detection: same fingerprint (loosened on time) recurring ~monthly → auto-promote to an `obligation` node with a `funds`/`competes_with` edge.
- Confidence tags carried per node, upgraded as corroborating sources arrive (SMS `inferred` → Gmail statement `confirmed`).

### 8.3 Intelligence layer
- **Anomaly baseline**: rolling percentile of spend by category/day-of-week per user; new event scored by deviation from baseline (z-score or percentile rank). Exponential recency weighting so legitimate behavior shifts don't stay flagged forever.
- **LLM reasoning agent** (Claude API): given a graph path + confidence tags + user's risk tolerance, generates the plain-language explanation. The LLM narrates and explains — it does not compute the cascade or the anomaly score; those come from the graph/stats layer as verified inputs.

### 8.4 Intervention gate
- Score = `f(severity, confidence, urgency)` — simple weighted formula for the hackathon (e.g. `severity × confidence × urgency_multiplier`), threshold tunable.
- Log every candidate insight (surfaced or suppressed) to `insights` table — this log is itself a demo asset ("3 candidates this week, 1 surfaced").

### 8.5 Mobile app (Flutter)
- **Onboarding**: Gmail OAuth consent screen, risk tolerance selection (low/medium/high), SMS permission (Android) or manual SMS paste (iOS fallback, since SMS read access is Android-only).
- **Insight feed**: card list of surfaced insights, each showing the explanation, severity, and a "why" expand that shows the graph path in plain language.
- **State view** (stretch): simple visual of the current graph — income sources, obligations, goals — good demo visual, doesn't need to be interactive.
- **Suppressed log** (stretch, strong demo moment): a debug/transparency screen showing what the gate held back and why.

## 9. Tech stack

| Layer | Choice |
|---|---|
| Mobile | Flutter |
| Backend API | Node.js/Express or Next.js API routes (reuse your existing TS familiarity) |
| DB | Postgres + Prisma |
| Auth | Google OAuth (Gmail readonly scope) |
| LLM | Claude API (reasoning/explanation agent) |
| Hosting | Whatever's fastest to stand up for the demo (Render/Railway/AWS — pick one and don't switch) |

## 10. Build plan (48 hr)

| Time | Milestone |
|---|---|
| 0–6h | Postgres schema live, SMS parser wired into common event schema, seed synthetic data |
| 6–14h | Gmail OAuth + parser working end-to-end on a real inbox |
| 14–20h | Fingerprinting/dedupe logic, node/edge creation from events |
| 20–28h | Recursive CTE cascade queries, anomaly baseline scoring |
| 28–34h | Intervention gate + LLM explanation call, insights table populated |
| 34–42h | Flutter app: onboarding, insight feed, wire to backend API |
| 42–46h | Demo script rehearsal, seed a clean demo dataset with a scripted cascade event |
| 46–48h | Buffer / bug fixes |

**Critical path risk**: Gmail parsing accuracy (email formats vary a lot). Mitigation: scope Gmail parsing to a small set of known formats (e.g. bank e-statement templates, common merchant receipt formats) rather than general-purpose parsing, and lean on synthetic data to backstop the demo if live parsing is flaky.

## 11. Demo script (what judges see)

1. Show the insight feed with a surfaced cascade warning.
2. Tap "why" → show the graph path in plain language, confidence tags visible.
3. Show the suppressed-insights log → prove the gate isn't spamming.
4. Trigger a live event (send a test SMS or email) → show it flow through ingestion → dedupe → graph update → new insight appear, live.
5. Explicitly state the architecture decision: Postgres-modeled graph over a graph DB, and why (see below) — pre-empt the question.

## 12. Key architecture decision — Postgres over a graph DB

Modeling the causal graph as adjacency-list tables (`nodes`/`edges`) in Postgres instead of standing up Neo4j:
- Graph is small and shallow (dozens of nodes, ≤5-hop cascades) — recursive CTEs handle this fine at this scale.
- One database instead of two — less integration risk in a 48hr build.
- Transactional data (events, users) is naturally relational anyway; a second DB would fragment it for no real performance gain at demo scale.
- Judges can inspect the schema and query directly, which is a stronger live-demo answer than a black-box graph query.

---

**Open items to confirm with your team before build starts:** exact gate scoring weights, which Gmail email formats to prioritize for parsing, and Android vs iOS as the primary demo device (affects the SMS-read fallback plan).
