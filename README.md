# AURA

### Autonomous Financial Intelligence for Variable-Income Users

> **An agentic system that transforms fragmented financial signals into proactive, explainable financial decisions.**

Built for **CSI ORIGIN 2026 — Problem Statement 1**

---

## The Problem

Variable-income users receive financial information across SMS, emails, bills, and transactions. Existing finance apps track what happened — but users still have to understand **what changed, what it affects, and what to do next**.

## Our Solution

AURA continuously ingests financial signals, builds an evolving financial state, detects risks, and proactively surfaces only the insights that matter.

```text
SMS + Gmail + Manual Input
            ↓
     Normalize & Deduplicate
            ↓
   Financial State Graph
            ↓
  Cascade + Anomaly Detection
            ↓
       Intervention Gate
            ↓
   AI-Powered Explanation
            ↓
       Flutter Application
```

---

## What Makes It Different

* **Causal Financial Graph** — models relationships between income, obligations, goals, and buffers.
* **Cascade Detection** — identifies how one event can affect downstream financial commitments.
* **Behavioral Anomalies** — detects significant deviations from historical spending patterns.
* **Intervention Gate** — filters low-value alerts using severity, confidence, and urgency.
* **Explainable AI** — provides users with clear reasoning behind every surfaced insight.

---

## Tech Stack

| Technology                   | Used For                                            |
| ---------------------------- | --------------------------------------------------- |
| **Flutter**                  | Mobile application and insight dashboard            |
| **Node.js + TypeScript**     | Backend APIs and agent orchestration                |
| **PostgreSQL**               | Financial state, events, insights, and causal graph |
| **Prisma**                   | Type-safe database access                           |
| **Google OAuth + Gmail API** | Email-based financial signal ingestion              |
| **SMS Parser**               | Transaction signal ingestion                        |
| **Claude API**               | Context-aware financial insight explanations        |

---

## Sponsor Technology

### Stitch

**Used for:** Financial data analysis and intelligence, helping transform fragmented financial signals into actionable insights.

### ElevenLabs

**Used for:** Converting important financial insights into natural voice briefings, enabling proactive audio-based financial updates.

### CodeCrafters

**Used for:** Supporting the systems-oriented engineering approach behind AURA's event pipeline, state management, database architecture, and financial reasoning engine.

### Nexus

**Used for:** Application infrastructure and deployment of backend services supporting the financial intelligence pipeline.

---

## The Core Idea

> **AURA does not simply track transactions. It understands how financial events are connected and determines when the user needs to act.**

A delayed income event can affect rent, savings, investments, and available cash. AURA identifies that cascade **before it becomes a missed financial obligation**.

---

**Built for CSI ORIGIN 2026**
*Autonomous • Proactive • Explainable*
