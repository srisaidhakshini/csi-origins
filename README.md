# Finova

Autonomous Financial Intelligence Platform for Variable-Income Users

An intelligent system that converts fragmented financial signals into proactive, explainable decisions.

Built for CSI ORIGIN 2026

---

## Team Details

Team Name: Cyber Catalysts

```
      \ O /            \ O /            \ O /            \ O /
        |                |                |                |
       / \              / \              / \              / \
  [Prodhosh VS]  [Sri Saidhakshini]  [Gowreesh VT]    [Avanthika]
```

* Prodhosh VS
* Sri Saidhakshini
* Gowreesh VT
* Avanthika

---

## Problem Statement

Variable-income earners—such as freelancers, gig workers, creators, and seasonal contractors—receive financial information scattered across transactional SMS, bank emails, PDF statements, physical bills, and platform payout notifications.

Current personal finance applications only log historical transactions after they occur. They do not help users understand three fundamental questions:
1. What changed across income and obligations?
2. How does an income delay cascade to downstream bills and rent deadlines?
3. What exact counter-measure should be taken before a liquidity shortfall occurs?

---

## Solution Overview

Finova is an autonomous agentic copilot that continuously ingests financial events, builds a dynamic causal state graph in PostgreSQL, detects downstream cascade failures using recursive graph traversal, and deliberates mitigation actions through an ensemble of specialized AI agents.

```
+-----------------------------------------------------------------------------+
|                               INGESTION LAYER                               |
|   Bank SMS Stream   |   Gmail Ingestion   |   Camera OCR   |  Manual Input  |
+-----------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------+
|                           NORMALIZATION & DEDUP                             |
|   - Regex Tokenizers & Gemini Vision Extraction                             |
|   - Hash-based Event Deduplication Engine                                   |
+-----------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------+
|                        CAUSAL FINANCIAL STATE GRAPH                         |
|   - PostgreSQL Schema with Adjacency Nodes & Directed Edges                 |
|   - Income Nodes -> Buffer Nodes -> Obligation Nodes (Rent, SIP, Bills)     |
+-----------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------+
|                         DETERMINISTIC GRAPH REASONING                       |
|   - Recursive CTE Cascade Detection Engine                                  |
|   - Deficit Day-of-Month Calculation & Shortfall Severity Scoring           |
+-----------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------+
|                           MULTI-AGENT DELIBERATION                          |
|   - Liquidity Auditor Agent                                                 |
|   - Gig Cashflow Forecaster Agent                                           |
|   - Behavioral Gatekeeper Agent                                             |
+-----------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------+
|                              INTERVENTION GATE                              |
|   - Threshold Check: (Severity * Confidence * Urgency) >= 0.70              |
|   - Prevents Alert Fatigue by Suppressing Low-Impact Noise                  |
+-----------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------+
|                        EXPLAINABLE ACTION & VOICE INTERFACE                 |
|   - ElevenLabs Neural Voice Synthesis & Real-Time Speech-to-Speech          |
|   - Web Speech API Recognition & Conversational Copilot                     |
|   - Proactive Emergency Voice Alerts with 1-Click Counter-Measures          |
|   - Cross-Platform Flutter Client (Web & Mobile)                            |
+-----------------------------------------------------------------------------+
```

---

## System Architecture & Core Modules

### 1. Multi-Source Ingestion Pipeline
* Bank SMS Stream: Extracts debits, credits, account numbers, and merchant details from live transactional notifications.
* Gmail OAuth Ingestion: Continuously monitors inbox for payment receipts, invoices, and bank alerts with idempotent transaction deduplication.
* Real-Time Camera OCR: Live camera viewfinder with frame capture processed through Gemini Vision to extract physical invoices and utility bills.

### 2. Causal Financial Graph
Instead of isolated database tables, Finova structures a user's financial life as a directed acyclic graph (DAG) in PostgreSQL:
* Node Types: Inflow (Client retainers, Upwork payouts), Buffer (Checking accounts, liquid savings), Outflow (Rent, EMIs, SIPs, utilities).
* Directed Edges: Map dependencies showing which specific income streams fund which obligations.

### 3. Recursive Cascade Detection Engine
When an expected income node is delayed or reduced, a PostgreSQL Recursive Common Table Expression (CTE) traverses downstream dependency edges to identify exactly which future obligations will face a shortfall, how many days until default, and the exact monetary deficit.

### 4. Multi-Agent Deliberation Council
A council of specialized agents analyzes the detected cascade:
* Liquidity Auditor: Analyzes checking buffer runway, overdraft risks, and liquidity margins.
* Gig Forecaster: Predicts probability of upcoming freelance payouts and variable income timing.
* Behavioral Gatekeeper: Evaluates user risk tolerance and historical spending deviations.

### 5. Mathematical Intervention Gate
To avoid notification fatigue, every candidate alert passes through a mathematical gate:
```
Intervention Score = Severity * Confidence * Urgency
Surfaced if Intervention Score >= 0.70
```

### 6. Voice AI & Real-Time Speech-to-Speech
* ElevenLabs Voice Integration: High-severity cascade risks are converted into natural spoken emergency briefings.
* Full Duplex Copilot: Users can tap the microphone to speak questions naturally (voice-to-text), receive instant financial reasoning over their PostgreSQL graph, and hear the response spoken aloud using ElevenLabs neural voice.

---

## Technology Stack

| Layer | Technologies |
| :--- | :--- |
| Frontend | Flutter Web & Mobile, Dart, Web Speech API |
| Backend Runtime | Node.js, Express, TypeScript |
| Database & Graph | PostgreSQL, Prisma ORM, Recursive CTE Queries |
| Neural Voice Engine | ElevenLabs API (eleven_turbo_v2_5) |
| Reasoning Models | Google Gemini 2.5 Flash, Gemini Vision |
| Ingestion & Auth | Google OAuth 2.0, Gmail API, Cashiro Engine |
| Infrastructure | Docker, Docker Compose, Nginx |

---

## Getting Started

### Prerequisites
* Docker & Docker Compose OR
* Node.js v20+, Flutter SDK 3.x, PostgreSQL 16+

### Quick Start with Docker

```bash
# 1. Clone the repository
git clone https://github.com/srisaidhakshini/csi-origins.git
cd csi-origins

# 2. Start all services via Docker Compose
docker compose up --build
```

Access the application:
* Web Application: http://localhost:8080
* Backend API: http://localhost:3000
* Prisma Studio Database GUI: http://localhost:5555

---

### Manual Local Setup

#### 1. Backend Setup
```bash
cd backend
npm install
npx prisma db push
npx ts-node prisma/seed.ts
npm run dev
```

#### 2. Frontend Setup
```bash
cd mobile
flutter pub get
flutter run -d chrome
```

---

## Key Differentiators

* Proactive Over Reactive: Detects future cashflow failure points days before they occur rather than displaying historical charts.
* Deterministic Core with Neural Interfaces: Uses deterministic graph math for balance integrity and generative AI solely for natural language explanation and reasoning.
* Zero Alert Fatigue: Mathematical scoring suppresses non-actionable financial noise.
* Dual Voice Interaction: Supports both incoming emergency spoken briefings and two-way voice deliberation over financial state.
