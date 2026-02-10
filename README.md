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

## 🛠️ Tech Stack

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
