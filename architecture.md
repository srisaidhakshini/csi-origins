# EscrowGuard Architecture & Dashboard Ecosystem

Based on the problem statement, here is the complete solution architecture mapped out across three distinct Mermaid diagrams. We break this down into the **Core System Pipeline**, the **3 Dashboard UI Architecture**, and the **Milestone State Machine**.

> [!TIP]
> This architecture separates the complex AI agent logic from the frontend dashboards. The users (Freelancers and Clients) never directly interact with the AI logic—they just submit work and receive phone calls, while the agents work autonomously in the background.

## 1. Core System & Agent Pipeline
This diagram shows how the 4 agents connect to external APIs and process the work.

```mermaid
graph TD
    subgraph Users
        F[Freelancer]
        C[Client]
    end

    subgraph Frontend Dashboards
        FD[Freelancer Portal]
        CD[Client Portal]
        AD[Admin/Agent Monitor]
    end

    subgraph Backend Core
        DB[(Database / Supabase)]
        API[API / Next.js Actions]
    end

    subgraph Agentic Pipeline
        AA[1. Audit Agent]
        SA[2. Strategy Agent]
        VA[3. Voice Agent]
        EA[4. Execution Agent]
    end

    subgraph External Infrastructure
        CC[CodeCrafters / GitHub]
        EL[ElevenLabs API]
        ST[Stitch Payment API]
    end

    %% Flow connections
    F -->|Submits Work| FD
    C -->|Funds Escrow| CD
    
    FD <--> API
    CD <--> API
    API <--> DB
    
    %% Agent Trigger Flow
    API -->|Triggers Verification| AA
    AA <-->|Tests code/pulls repo| CC
    AA -->|Passes Audit Results| SA
    SA -->|Calculates % Payout| VA
    
    %% Voice Agent Flow
    VA <-->|Streams Phone Call to F & C| EL
    EL -.->|Calls| F
    EL -.->|Calls| C
    
    VA -->|Verbal Consent Achieved| EA
    EA <-->|Triggers Bank Transfer| ST
```

---

## 2. The 3 Dashboards: Pages & Navigation
As you suggested, we need exactly 3 dashboards. 
1. **Client Dashboard**: For managing money and seeing audit results.
2. **Freelancer Dashboard**: For submitting work and tracking payouts.
3. **Admin Observability**: For developers to monitor the AI agents in real-time.

```mermaid
flowchart LR
    subgraph Authentication
        Auth[Login / Sign Up]
    end

    subgraph Client Dashboard
        C_Home[Active Contracts]
        C_Fund[Deposit to Escrow]
        C_Audit[View AI Audit Reports]
        C_Voice[Voice Consent Logs]
    end

    subgraph Freelancer Dashboard
        F_Home[My Milestones]
        F_Submit[Submit GitHub PR / Work]
        F_Status[Payout Tracker]
    end

    subgraph Admin Observability Dashboard
        A_Home[System Health]
        A_Logs[Agent Trace Logs]
        A_Dispute[Manual Dispute Override]
    end

    Auth --> C_Home
    Auth --> F_Home
    Auth --> A_Home

    %% Client Links
    C_Home --> C_Fund
    C_Home --> C_Audit
    C_Audit --> C_Voice

    %% Freelancer Links
    F_Home --> F_Submit
    F_Submit --> F_Status

    %% Admin Links
    A_Home --> A_Logs
    A_Logs --> A_Dispute
```

---

## 3. Escrow Milestone Lifecycle (State Machine)
This maps the exact states a project goes through. This is crucial for your database schema (e.g., an `status` enum column on your `Milestones` table).

```mermaid
stateDiagram-v2
    [*] --> Draft: Contract Created
    Draft --> Funded: Client deposits money via Stitch
    
    Funded --> Auditing: Freelancer submits work
    
    Auditing --> Rejected: Audit Agent fails the work
    Rejected --> Auditing: Freelancer fixes & resubmits
    
    Auditing --> Negotiating: Audit Agent approves work
    
    Negotiating --> Released: Voice Agent secures dual consent
    Negotiating --> Dispute: Voice Agent fails to get agreement
    
    Released --> [*]: Execution Agent transfers funds
    Dispute --> [*]: Fallback to manual resolution
```

> [!IMPORTANT]
> **Next Steps for Development**
> 1. Set up the routes for the 3 dashboards (`/app/dashboard/client`, `/app/dashboard/freelancer`, `/app/dashboard/admin`).
> 2. Build the state tracking in the database (`status: 'FUNDED' | 'AUDITING' | 'NEGOTIATING' | 'RELEASED'`).
> 3. Connect the Voice Agent webhook so that when ElevenLabs finishes the call, it triggers the Execution Agent.
