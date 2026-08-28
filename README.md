# FINOVA

### Autonomous Financial Intelligence for Variable-Income Users

> **An agentic system that transforms fragmented financial signals into proactive, explainable financial decisions.**

Built for **CSI ORIGIN 2026 — Problem Statement 1**

---

## 👥 Team Details

### **Team Name:** Cyber Catalysts

| Team Member | Role |
| :--- | :--- |
| **Prodhosh VS** | System Architecture, Backend & Agent Pipeline |
| **Sri Saidhakshini** | Intelligence Engine, Causal State Graph & Deliberation Council |
| **Gowreesh VT** | Full-Stack Integration, Multi-Source Ingestion & APIs |
| **Avanthika** | Mobile UI/UX Design, Flutter Application & Data Modeling |

---

## 💡 The Problem

Variable-income users receive financial information across SMS, emails, bills, and transactions. Existing finance apps track what happened — but users still have to understand **what changed, what it affects, and what to do next**.

---

## 🚀 Our Solution

FINOVA continuously ingests financial signals, builds an evolving financial state, detects risks, and proactively surfaces only the insights that matter.

```text
SMS + Gmail + Manual Input + OCR
             ↓
      Normalize & Deduplicate
             ↓
    Financial State Graph (Postgres)
             ↓
   Cascade (Recursive CTE) + Anomaly Detection
             ↓
   Multi-Agent Council Deliberation
             ↓
        Intervention Gate
             ↓
    AI-Powered Explanation (Voice + Text)
             ↓
        Flutter Application
```

---

## ✨ What Makes It Different

* **Causal Financial Graph** — models relationships between income, obligations, goals, and buffers in PostgreSQL.
* **Cascade Detection** — identifies how one delayed income event creates downstream defaults using deterministic Recursive CTE graph traversal.
* **Multi-Agent Council** — deliberates across Liquidity Auditor, Gig Forecaster, and Behavioral Gatekeeper specialists.
* **Behavioral Anomalies** — detects significant deviations from historical spending patterns using recency-weighted statistics.
* **Intervention Gate** — mathematically filters low-value alerts using severity, confidence, and urgency thresholds.
* **Proactive Voice Alerts** — converts critical insights into spoken emergency briefings with 1-click counter-actions.
* **Explainable AI** — provides users with transparent audit traces and reasoning behind every surfaced decision.

---

## 🛠️ Tech Stack

| Technology | Used For |
| :--- | :--- |
| **Flutter (Web & Mobile)** | High-performance reactive frontend & onboarding |
| **Node.js + TypeScript** | Backend APIs and multi-agent orchestration |
| **PostgreSQL** | Adjacency list causal graph, events, and insights |
| **Prisma** | Type-safe database ORM and migrations |
| **Google OAuth + Gmail API** | Email-based transaction ingestion & deduplication |
| **Cashiro SMS Normalizer** | Bank SMS transaction signal extraction |
| **ElevenLabs & Web Audio** | Conversational voice alerts & simulated emergency calls |
| **Gemini & Claude APIs** | Multi-agent reasoning and explainability |

---

## 🎙️ Sponsor Technology

### ElevenLabs

**Used for:** Converting high-severity cascade risks into natural, conversational voice briefings, enabling proactive audio-based emergency interventions with 1-click counter-actions.

---

## 🎯 The Core Idea

> **FINOVA does not simply track transactions. It understands how financial events are connected and determines when the user needs to act.**

A delayed income event can affect rent, savings, investments, and available cash. FINOVA identifies that cascade **before it becomes a missed financial obligation**.

---

**Built with ❤️ for CSI ORIGIN 2026 by Cyber Catalysts**

*Autonomous • Proactive • Explainable*
