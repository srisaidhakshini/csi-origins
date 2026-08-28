# ⚡ CASCADE

### **Your finances don't fail all at once. They fail in a chain.**

> **CASCADE is an autonomous AI financial agent that continuously understands a user's evolving financial reality, predicts how one financial event can affect everything downstream, and intervenes only when it truly matters.**

**Built for CSI ORIGIN 2026 — Problem Statement 1**  
**Autonomous Financial Management for Variable-Income Users**

---

## 🌊 The Problem

For a salaried employee, financial planning often assumes something predictable:

```text
Salary arrives → Expenses happen → Savings happen
```

But for a freelancer, gig worker, informal-sector worker, or young earner, reality looks different:

```text
Income may arrive late
        ↓
Upcoming obligations remain fixed
        ↓
Unexpected spending occurs
        ↓
Savings goals compete for limited cash
        ↓
One small change can affect everything downstream
```

Financial information is also fragmented across:

- 💳 Transactions
- 📩 SMS notifications
- 📧 Emails and receipts
- 🧾 Bills
- 🎯 Savings goals
- 🔁 Recurring obligations
- 📈 Investment commitments

Existing financial applications mostly answer:

> **"What happened to my money?"**

But users with variable income need something more important:

> **"What is likely to happen next—and what should I do before it becomes a problem?"**

---

# 🎯 Our Solution

## **CASCADE is not another expense tracker.**

CASCADE maintains a continuously evolving model of a user's financial state.

Every financial signal can trigger a chain of reasoning:

```text
New Financial Signal
        ↓
Normalize & Verify
        ↓
Update Financial State
        ↓
Trace Downstream Dependencies
        ↓
Detect Cascade Risk / Behavioral Anomaly
        ↓
Evaluate Severity × Confidence × Urgency
        ↓
Intervention Gate
        ↓
        ├── SUPPRESS
        │
        └── INTERVENE
                 ↓
         AI Explains WHY
                 ↓
      Contextual Recommended Action
```

The core innovation is simple:

> ## **CASCADE does not wait for users to ask for help.**
>
> It continuously observes financial changes, reasons about consequences, and decides whether intervention is actually necessary.

---

# 🧠 The Core Innovation: Financial Causal Intelligence

Traditional finance apps see transactions as isolated records.

CASCADE sees them as **connected financial events**.

For example:

```text
┌─────────────────────┐
│ Freelance Payment   │
│      ₹15,000        │
└──────────┬──────────┘
           │ funds
           ▼
┌─────────────────────┐
│ Available Cash      │
└──────┬────────┬─────┘
       │        │
       ▼        ▼
    ┌─────┐  ┌─────┐
    │Rent │  │ EMI │
    └──┬──┘  └─────┘
       │
       ▼
┌─────────────────────┐
│ Savings / Buffer    │
└─────────────────────┘
```

Now imagine:

> **Expected freelance payment delayed.**

CASCADE does not simply record that event.

It asks:

```text
What does this change?
        ↓
How much expected cash is now missing?
        ↓
Which obligations depend on that cash?
        ↓
What happens if the income does not arrive?
        ↓
Which goal or commitment should be deprioritized?
        ↓
Does this require interrupting the user?
```

The resulting reasoning chain becomes:

```text
Delayed Income
      ↓
Lower Expected Cash
      ↓
Reduced Safety Buffer
      ↓
Upcoming Rent at Risk
      ↓
Savings Goal Competes for Cash
      ↓
Recommendation Required
```

This is the **CASCADE Engine**.



# 🧬 What Makes CASCADE Different?

## 1. 🔗 Financial Causal Graph

CASCADE maintains a graph of the user's financial world.

### Nodes

- Income sources
- Recurring obligations
- Upcoming expenses
- Savings goals
- Emergency buffers
- Investment commitments

### Relationships

- `FUNDS`
- `COMPETES_WITH`
- `BUFFERS_AGAINST`
- `DEPENDS_ON`
- `IMPACTS`

Example:

```text
Income
  │
  ├──── FUNDS ────► Rent
  │
  ├──── FUNDS ────► EMI
  │
  └──── COMPETES_WITH ────► Savings Goal
```

When one node changes, CASCADE traces the downstream impact.

> **We don't just detect financial events. We understand financial consequences.**

---

# 🛡️ 2. Confidence-Aware Financial State

Financial information is not always equally reliable.

A message from SMS, an email receipt, a manually entered expense, and a predicted future payment should not all be treated as absolute facts.

CASCADE explicitly distinguishes:

| Confidence | Meaning |
|---|---|
| 🟢 **Confirmed** | Verified by reliable evidence |
| 🟡 **Inferred** | Derived from recurring patterns or available signals |
| 🔵 **Predicted** | Estimated future condition |

Example:

```text
Rent ₹8,000
Status: Confirmed

Freelance payment ₹15,000
Status: Predicted

Upcoming utility bill ₹1,200
Status: Inferred
```

This ensures that CASCADE does not present uncertainty as certainty.

---

# 🧩 3. Multi-Source Financial Intelligence

Financial data enters through multiple fragmented sources:

```text
             ┌───────────┐
             │    SMS    │
             └─────┬─────┘
                   │
             ┌─────▼─────┐
             │   Gmail   │
             └─────┬─────┘
                   │
             ┌─────▼─────┐
             │  Receipts │
             └─────┬─────┘
                   │
             ┌─────▼─────┐
             │   Manual  │
             └─────┬─────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ Common Event Schema │
        └──────────┬──────────┘
                   ▼
          Normalize + Fingerprint
                   ▼
              Deduplicate
                   ▼
        Update Financial Reality
```

### Duplicate Detection

The same transaction may appear in:

- SMS
- Email receipt
- Bank notification

CASCADE fingerprints events using:

```text
Amount Bucket
      +
Normalized Merchant
      +
Time Window
      ↓
Unique Financial Fingerprint
```

Instead of duplicating financial information, CASCADE merges corroborating evidence and can increase confidence.

---

# 📈 4. Behavioral Anomaly Intelligence

CASCADE learns what is normal for each user.

It does not rely on generic spending rules.

Instead, it evaluates deviations from a personal baseline.

Example:

```text
Normal monthly dining spend: ₹3,000

Current dining spend: ₹8,500
```

CASCADE does not immediately assume the user made a mistake.

It considers the broader context:

> Your dining expenditure is significantly above your usual pattern. This may not be a problem by itself, but because your expected income this month is uncertain, the increase could reduce your safety buffer.

This makes recommendations:

- Contextual
- Personalized
- Risk-aware
- Less judgmental
- More useful

---

# 🚦 5. The Intervention Gate

## The intelligence of an agent is not only knowing what to say.

## **It is knowing when not to interrupt.**

Most financial applications generate endless alerts.

CASCADE introduces an **Intervention Gate**.

Every candidate insight is evaluated using:

```text
             Severity
                 ×
             Confidence
                 ×
              Urgency
                 │
                 ▼
        ┌─────────────────┐
        │ Intervention    │
        │      Gate       │
        └────────┬────────┘
                 │
          ┌──────┴──────┐
          ▼             ▼
      SUPPRESS      INTERVENE
```

### Example

| Event | Impact | Decision |
|---|---|---|
| ₹120 coffee purchase | Low | Suppress |
| ₹350 shopping variation | Low | Suppress |
| Unusual ₹8,000 expense | Medium/High | Evaluate |
| Delayed ₹15,000 income before rent | Critical | Surface |

The system keeps a transparent record of both:

- **Insights surfaced**
- **Insights intentionally suppressed**

### A powerful product principle

> **CASCADE may analyze 50 events and choose to interrupt the user only once.**

Because attention is also a limited financial resource.

---

# 🧠 6. AI Explains. The Financial Engine Calculates.

CASCADE does not ask an LLM to blindly analyze raw transactions.

Instead:

```text
Financial Signals
       ↓
Deterministic Calculations
       ↓
Graph Propagation
       ↓
Anomaly Detection
       ↓
Verified Risk Context
       ↓
AI Reasoning Agent
       ↓
Human Explanation
       ↓
Recommended Action
```

The financial engine determines:

- What changed
- What depends on it
- What is statistically unusual
- How severe the impact is
- How confident the system is

The AI agent then answers:

> **What does this mean for the user?**

> **Why does it matter now?**

> **What action should be considered?**

> **Why is this recommendation being made?**

This creates a system that is both **intelligent and explainable**.

---

# 🔍 7. Every Recommendation Has a “Why?”

CASCADE never gives a black-box recommendation.

Every insight includes an explainable reasoning path.

### Example

```text
WHY AM I SEEING THIS?

Delayed Freelance Payment
          ↓
Expected Income Reduced
          ↓
Available Cash Reduced
          ↓
Rent Due in 6 Days
          ↓
Emergency Buffer Insufficient
          ↓
⚠️ CASH-FLOW RISK
```

The user can see:

- What triggered the insight
- Which financial dependencies were affected
- What information is confirmed
- What information is inferred
- Why the recommendation was generated

---

# ⚖️ 8. Competing Financial Objectives

CASCADE understands that money cannot satisfy every objective simultaneously.

Example:

```text
Available Funds: ₹10,000

Priority Requirements:

1. Rent                ₹5,000
2. EMI                 ₹2,000
3. Emergency Buffer    ₹2,000
4. Savings Goal        ₹3,000
5. SIP                 ₹2,000
```

A traditional tracker simply shows these values.

CASCADE reasons across them.

### CASCADE Recommendation

> Your current funds cannot safely satisfy every objective. Because your income is uncertain and rent is due soon, CASCADE recommends temporarily prioritizing essential obligations and the emergency buffer over discretionary savings commitments.

This is **financial prioritization under uncertainty**, not transaction visualization.

---

# 🏗️ Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                         LOVABLE                             │
│                                                             │
│  Dashboard • Insight Feed • Why View • Financial Graph      │
│  Risk Profile • Goals • Suppressed Insight Log              │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                         n8n                                 │
│                                                             │
│           AUTONOMOUS FINANCIAL ORCHESTRATION                │
│                                                             │
│  Ingestion → State Update → Detection → Intervention        │
│                    → AI Explanation                         │
└───────┬─────────────────┬──────────────────┬────────────────┘
        │                 │                  │
        ▼                 ▼                  ▼
   SMS Parser        Gmail Parser       Scheduled Agent
        │                 │                  │
        └─────────────────┴──────────────────┘
                          │
                          ▼
                ┌──────────────────┐
                │ NORMALIZE +      │
                │ FINGERPRINT      │
                │ + DEDUPLICATE    │
                └────────┬─────────┘
                         ▼
                ┌──────────────────┐
                │    SUPABASE      │
                │                  │
                │ Postgres State   │
                │ Financial Graph  │
                │ Events           │
                │ Insights         │
                └────────┬─────────┘
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
   Cascade Engine   Anomaly Engine   Priority Engine
          │              │              │
          └──────────────┴──────────────┘
                         ▼
                ┌──────────────────┐
                │ INTERVENTION     │
                │      GATE        │
                └────────┬─────────┘
                         ▼
                 ┌───────────────┐
                 │  AI REASONING │
                 │     AGENT     │
                 └───────┬───────┘
                         ▼
                    INSIGHT FEED
```

---

# 🛠️ Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Frontend | **Lovable** | Rapid premium UI development |
| Database | **Supabase PostgreSQL** | Financial state and relational graph |
| Authentication | **Supabase Auth / Google OAuth** | User authentication |
| Automation | **n8n** | Agent orchestration and workflows |
| AI | **LLM API** | Contextual reasoning and explanation |
| Data Source | **SMS Parser** | Transaction signal extraction |
| Data Source | **Gmail Read-Only OAuth** | Receipt, bill and financial signal extraction |
| Realtime | **Supabase Realtime** | Live insight updates |

---

# 🗄️ Financial State Model

CASCADE represents the user's financial world as an evolving graph.

## Core Nodes

```text
Income Source
Obligation
Goal
Emergency Buffer
Recurring Expense
Investment Commitment
```

## Core Relationships

```text
FUNDS
COMPETES_WITH
BUFFERS_AGAINST
DEPENDS_ON
IMPACTS
```

## Example

```text
[Freelance Income]
        │
        │ FUNDS
        ▼
[Available Cash]
     │        │
     ▼        ▼
  [Rent]    [EMI]
     │
     │ COMPETES_WITH
     ▼
[Savings Goal]
```

When a financial node changes, CASCADE can trace the resulting dependency chain.

---

# ⚙️ Autonomous Workflows

## Workflow 1 — Financial Signal Ingestion

```text
New SMS / Gmail / Manual Event
            ↓
Validate
            ↓
Normalize
            ↓
Generate Fingerprint
            ↓
Duplicate?
      ↙           ↘
    YES            NO
     ↓              ↓
Merge Evidence   Create Event
     ↓              ↓
     └──────┬───────┘
            ↓
Update Financial State
```

---

## Workflow 2 — Cascade Detection

```text
Financial State Changed
          ↓
Identify Changed Node
          ↓
Traverse Dependencies
          ↓
Evaluate Downstream Impact
          ↓
Calculate Financial Risk
          ↓
Generate Candidate Insight
```

---

## Workflow 3 — Behavioral Anomaly Detection

```text
New Transaction
       ↓
Retrieve Personal Baseline
       ↓
Compare Current Behavior
       ↓
Deviation Score
       ↓
Context Evaluation
       ↓
Candidate Insight
```

---

## Workflow 4 — Autonomous Intervention

```text
Candidate Insight
       ↓
Severity Score
       +
Confidence Score
       +
Urgency Score
       ↓
INTERVENTION GATE
       ↓
   ┌───┴────┐
   ▼        ▼
Suppress  Surface
             ↓
      AI Explanation
             ↓
    Contextual Action
             ↓
      User Insight Feed
```

---

# 📱 Product Experience

## 🏠 Financial Command Center

Instead of overwhelming users with charts, CASCADE answers one question first:

> **How safe is my financial position right now?**

The dashboard highlights:

- Financial stability
- Upcoming obligations
- Safe-to-spend estimate
- Active risks
- Emerging opportunities

---

## 🚨 Insight Feed

The most important screen.

Example:

### ⚠️ Potential Cash-Flow Risk

**Severity:** High  
**Confidence:** 88%

> A delayed income payment may affect your ability to safely cover rent due in 6 days.

**Recommended action:**

> Prioritize your rent obligation and consider postponing this month's SIP contribution.

**[ WHY? ]**

---

## 🔍 Why View

```text
Payment Delayed
       ↓
Income Confidence Reduced
       ↓
Expected Cash Reduced
       ↓
Rent Obligation Approaching
       ↓
Safety Buffer Below Threshold
       ↓
RECOMMENDATION GENERATED
```



## 3. Show the Autonomous Agent Working

```text
✓ Signal detected
✓ Data normalized
✓ Duplicate check complete
✓ Financial state updated
✓ Dependencies analyzed
✓ Cascade detected
✓ Intervention gate evaluated
✓ Insight generated
```

---

## 4. The Insight Appears

> ⚠️ **Potential Rent Risk Detected**

The user never asked a question.

The agent acted proactively.

---

## 5. Open “Why?”

Show the complete causal chain.

This proves the recommendation is explainable.

---

## 6. Open Suppressed Insights

Show that the system deliberately ignored lower-impact events.

### Final line:

> ## **"The intelligence of our agent is not just knowing what to say. It is knowing what not to say."**

---

### Most finance apps:

```text
Track → Visualize → Wait for User
```

### CASCADE:

```text
Perceive
   ↓
Understand
   ↓
Maintain State
   ↓
Predict Consequences
   ↓
Prioritize Objectives
   ↓
Decide Whether to Intervene
   ↓
Explain Why
   ↓
Recommend Action
```

---

# 📌 Alignment with the Problem Statement

| Requirement | CASCADE Implementation |
|---|---|
| Fragmented financial information | SMS + Gmail + receipts + manual input |
| Evolving financial state | Continuously updated financial graph |
| Variable income | Confidence-aware income projections |
| Recurring obligations | Pattern detection and obligation nodes |
| Discretionary spending | Behavioral anomaly analysis |
| Upcoming expenses | Obligation tracking |
| Savings goals | Goal nodes and priority reasoning |
| Proactive risk detection | Autonomous scheduled/event-driven workflows |
| Contextual recommendations | Financial state + risk profile |
| Explainability | Causal “Why?” graph |
| Incomplete/noisy data | Fingerprinting + confidence tags |
| Competing objectives | Priority and dependency reasoning |
| Risk tolerance | Personalized intervention and recommendations |
| Avoid excessive alerts | Intervention Gate |
| Autonomous decision support | End-to-end agent loop |

---

# 🔐 Responsible AI & Data Principles

CASCADE is designed around an important principle:

> **Financial uncertainty should never be hidden behind confident AI language.**

Therefore:

- Confirmed, inferred and predicted information are differentiated.
- Recommendations include reasoning context.
- Duplicate financial signals are detected before affecting state.
- The intervention gate reduces unnecessary alerts.
- The AI explains verified analytical outputs rather than inventing financial calculations.

For the hackathon MVP, production-grade financial compliance, full banking integration, and portfolio management are intentionally outside the core scope. The project focuses on demonstrating the autonomous decision-support loop using available financial signals.

---

# 🚀 Future Vision

CASCADE can evolve into a broader **Autonomous Financial Operating System**.

### Future capabilities:

- Real-time bank account integrations
- UPI and transaction stream analysis
- Calendar-aware financial planning
- Voice-based financial agent
- Autonomous bill negotiation recommendations
- Dynamic emergency fund optimization
- Financial scenario simulation
- Multi-goal planning
- Personalized intervention learning
- Privacy-preserving on-device financial intelligence

---

# 💡 The Big Idea

Financial problems rarely appear suddenly.

They emerge through connected events.

A delayed payment affects available cash.

Lower available cash affects obligations.

Obligations compete with goals.

Goals affect buffers.

Buffers determine resilience.

Traditional finance apps show the individual events.

## **CASCADE sees the chain.**

---

# ⚡ CASCADE

### **See the financial chain before it breaks.**

> **From financial tracking to autonomous financial intelligence.**
>
> **From reacting to problems to predicting consequences.**
>
> **From generic alerts to explainable intervention.**

---

## 🏁 Built for

**CSI ORIGIN 2026**

### Problem Statement 1
## **Autonomous Financial Management for Variable-Income Users**

---

<p align="center">
  <b>Signal → State → Cascade → Decision → Intervention → Explanation</b>
</p>

<p align="center">
  <i>CASCADE — Because your finances are connected.</i>
</p>
