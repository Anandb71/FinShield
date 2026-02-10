# FinShield 🛡️

> **AI-Powered Financial Document Forensics Platform**

FinShield is an autonomous auditing system that ingests financial documents (bank statements, invoices, payslips), detects fraud in real time, and visualizes forensic intelligence through an interactive knowledge graph.

---

## 🚀 Key Features

### Fraud Detection Engine
- **Metadata Integrity Check** — Compares header/summary balances against calculated transaction balances. Catches "lying headers" where the closing balance has been tampered with (e.g. injecting a -61M balance into a statement that actually closes at ₹61).
- **Benford's Law Analysis** — Flags unnatural leading-digit distributions in transaction amounts.
- **Structuring / Smurfing Detection** — Identifies clusters of transactions just below reporting thresholds.
- **Round-Number Syndrome** — Detects suspiciously high ratios of round-number transactions.
- **Date-Sequence Violations** — Catches out-of-order or impossible date progressions.
- **Balance Continuity Checks** — Verifies running balance consistency across every row.

### Lie Detector Panel
- Dynamic integrity display on the Review page — shows **INTEGRITY FAILURE** (red) or **INTEGRITY VERIFIED** (green) based on real-time comparison of reported vs calculated balances.
- 3-priority fallback: backend `metadata_discrepancy` → anomaly structured fields → local transaction comparison.
- Zero hardcoded values — all thresholds computed from actual data.

### Excel Normalization ("The Repair Shop")
- Parses messy bank statement spreadsheets from any bank layout.
- Auto-detects header rows, column mappings, date formats.
- Repairs OCR artifacts, skips junk rows, handles merged cells.
- Extracts opening/closing balances from summary sections.
- Infers transaction types (debit/credit) from signed amounts.

### Investigation Board (Knowledge Graph)
- **Interactive 3D Graph** — Navigate documents, entities, and risk nodes.
- **Conflict Hunter** — Detects shared addresses/phones between vendors and employees.
- **Entity Resolution** — Links accounts, names, and references across documents.

### X-Ray Reconciliation
- **Smart Match** — Auto-links invoices to bank transactions (exact & fuzzy).
- **Ghost Detection** — Flags invoices with no matching payment.
- **Human-in-the-Loop** — Force-match decisions feed the learning loop.

---

## � Project Evolution

### Before Review 1 (Feb 8, 2026)

**Original Vision**: FinShield was initially built as **"The Financial Flight Recorder"** — an autonomous, real-time defense system for mobile users. It attempted to solve **two sponsor track challenges** simultaneously for the I'M Hackathon:

1. **Call Shield (Hotfoot Audio track)** — Real-time analysis of phone calls to detect urgency manipulation, fear tactics, and pressure techniques used by scammers. Used WebSocket streaming with a live risk meter.
2. **Contract Scanner (Hotfoot Docs + Backboard track)** — Instant detection of predatory clauses, hidden fees, and exploitative terms in financial documents, with cross-referencing via Backboard RAG.

**Tech at this stage:**
- **Frontend**: Flutter with Riverpod state management, cybersecurity dark theme with neon accents, glassmorphism cards, animated shield logo, and a `call_shield_screen.dart` with a real-time risk meter
- **Backend**: FastAPI with mock service implementations for Hotfoot Audio (`audio_analyzer.py`), Hotfoot Docs (`document_scanner.py`), and Backboard RAG (`context_engine.py`)
- **Real-time pipeline**: WebSocket-based streaming (`sockets.py` + `ConnectionManager`) with `audio_processor.py` stub and `document_engine.py` stub
- **Architecture**: Monorepo with `/frontend` (Flutter) and `/backend` (FastAPI), Docker Compose for full-stack dev

**Key commits:**
| Commit | Date | Description |
|--------|------|-------------|
| [`8ef22ce`](https://github.com/Anandb71/FinShield/commit/8ef22ce) | Feb 8 | Initial project setup — Flutter + FastAPI + mock Hotfoot Audio/Docs/Backboard |
| [`c1e1a27`](https://github.com/Anandb71/FinShield/commit/c1e1a27) | Feb 8 | Add Flutter lib source files (home screen, glassmorphism widgets) |
| [`f3616fb`](https://github.com/Anandb71/FinShield/commit/f3616fb) | Feb 8 | Phase 2: WebSocket Pipeline — audio_processor stub, call_shield_screen with risk meter |

---

### After Review 1 → Before Review 2 (Feb 9–10, 2026)

**The Pivot**: After Review 1 feedback, we made a strategic decision to **drop the audio/call analysis track entirely** and go all-in on **document forensic intelligence**. The project evolved from a dual-challenge attempt into a focused, deep financial document auditing platform.

**What changed and why:**

| What Changed | Why |
|---|---|
| **Dropped Hotfoot Audio** (deleted `audio_analyzer.py`, `audio_processor.py`, `call_shield_screen.dart`) | Spreading across two sponsor tracks diluted depth. Document intelligence had more forensic potential. |
| **Flutter → React webapp** (new `/webapp` with React 18 + TypeScript + Vite + Chakra UI) | Flutter was great for mobile but the use case shifted to a desktop-first investigator dashboard. React + Chakra UI enabled faster iteration on complex data-heavy UIs (tables, charts, graphs). |
| **Mock services → Real AI pipeline** (Backboard Assistant API integration with GPT-4o) | Replaced mock implementations with actual LLM-powered document classification, field extraction, and validation. |
| **Added forensic analysis suite** | Benford's Law, balance integrity checks, structuring detection, metadata fraud detection — none of this existed pre-review. |
| **Added Knowledge Graph** | Cross-document entity resolution with interactive force-directed visualization. Links accounts, vendors, and counterparties across uploaded documents. |
| **Added Excel Normalization Engine** | Parses messy bank statement spreadsheets from any bank layout — auto-detects headers, columns, date formats. |
| **Added Self-Learning Loop** | Human corrections feed back into the system. Error clustering, retraining triggers, continuous improvement. |
| **Rebranded to Aegis** | Reflected the evolved mission — from a "shield" to a full forensic auditing platform. |

**Key commits in this phase:**
| Commit | Date | Description |
|--------|------|-------------|
| [`05fffb1`](https://github.com/Anandb71/FinShield/commit/05fffb1) | Feb 9 | **THE PIVOT** — Finsight Knowledge Graph & Reconciliation |
| [`e89bb45`](https://github.com/Anandb71/FinShield/commit/e89bb45) | Feb 9 | Backboard-only document intelligence system (classification, validation, entity resolution, learning loop) |
| [`d03a5f5`](https://github.com/Anandb71/FinShield/commit/d03a5f5) | Feb 9 | Universal Pipeline Dashboard with Bulk Ingestion and Review Queue |
| [`7b5b646`](https://github.com/Anandb71/FinShield/commit/7b5b646) | Feb 9 | Complete frontend rebuild — **audio services deleted**, industry-grade Flutter redesign |
| [`0e5c3e2`](https://github.com/Anandb71/FinShield/commit/0e5c3e2) | Feb 10 | Fix 10 diagnosed bugs + Excel viewer |
| [`2852da7`](https://github.com/Anandb71/FinShield/commit/2852da7) | Feb 10 | Metadata integrity fraud detection (Lie Detector panel) |
| [`ecf29f1`](https://github.com/Anandb71/FinShield/commit/ecf29f1) | Feb 10 | Enrich knowledge graph with accounts, balances & counterparties |
| [`089f663`](https://github.com/Anandb71/FinShield/commit/089f663) | Feb 10 | **Rebrand**: Finsight/FinShield → Aegis everywhere |
| [`6b59238`](https://github.com/Anandb71/FinShield/commit/6b59238) | Feb 10 | UI: Dramatically improve DocumentReviewPage inspector UI |

**The Flutter frontend still exists in `/frontend` as a legacy reference**, but the primary interface is now the React webapp in `/webapp`.

---

## �🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Backend** | Python 3.13, FastAPI, SQLModel, SQLAlchemy, SQLite |
| **AI/LLM** | OpenAI GPT-4o (via Backboard client) |
| **Excel Parsing** | openpyxl |
| **Frontend (Web)** | React 18, TypeScript, Vite, Chakra UI |
| **Visualization** | react-force-graph-3d, Recharts, react-pdf |
| **Frontend (Mobile)** | Flutter (legacy, in `/frontend`) |

---

## 🏃‍♂️ Quick Start

### Backend
```bash
cd backend
python -m venv ../.venv
../.venv/Scripts/activate   # Windows
pip install -e ".[dev]"
uvicorn app.main:app --reload --port 8000
```

### Web Frontend
```bash
cd webapp
npm install
npm run dev   # → http://localhost:5173
```

### Flutter Frontend (legacy)
```bash
cd frontend
flutter run -d chrome
```

---

## 📁 Project Structure

```
FinShield/
├── backend/           # FastAPI server + AI pipeline
│   ├── app/
│   │   ├── api/       # REST endpoints (ingestion, documents, forensics, review, dashboard)
│   │   ├── services/  # Excel normalizer, validation engine, backboard client
│   │   ├── db/        # SQLModel models + session management
│   │   └── core/      # Settings, knowledge graph store
│   └── storage/       # Uploaded document files
├── webapp/            # React + Vite frontend
│   └── src/
│       ├── pages/     # Dashboard, DocumentReview, Upload
│       └── components/
├── frontend/          # Flutter frontend (legacy)
└── docker-compose.yml
```

---

## 📍 Roadmap
- [x] Document ingestion pipeline with AI classification
- [x] Excel bank statement normalization engine
- [x] Forensic validation suite (Benford, structuring, balance checks)
- [x] Metadata integrity fraud detection (Lie Detector)
- [x] React web dashboard with document review
- [x] Knowledge graph entity resolution
- [ ] Multi-currency support (dynamic round-number thresholds)
- [ ] Automated report generation
- [ ] Batch re-analysis on rule updates
