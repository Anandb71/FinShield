# FinShield — Comprehensive Technical Analysis

> **Prepared for:** Pitch / Technical Due Diligence  
> **Version:** 2.0.0 (branded "Finsight")  
> **Repository:** [github.com/Anandb71/FinShield](https://github.com/Anandb71/FinShield)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [System Architecture](#2-system-architecture)
3. [Technology Stack](#3-technology-stack)
4. [Key Algorithms & Techniques](#4-key-algorithms--techniques)
5. [Feature Inventory](#5-feature-inventory)
6. [Data Flow — End to End](#6-data-flow--end-to-end)
7. [Backend Deep Dive](#7-backend-deep-dive)
8. [React Webapp Deep Dive](#8-react-webapp-deep-dive)
9. [Flutter Mobile App](#9-flutter-mobile-app)
10. [Database Schema](#10-database-schema)
11. [API Surface](#11-api-surface)
12. [Infrastructure & DevOps](#12-infrastructure--devops)
13. [Codebase Metrics](#13-codebase-metrics)
14. [Security Considerations](#14-security-considerations)
15. [Scalability Discussion](#15-scalability-discussion)
16. [Differentiators & Novel Techniques](#16-differentiators--novel-techniques)
17. [Anticipated Technical Questions & Answers](#17-anticipated-technical-questions--answers)

---

## 1. Executive Summary

**FinShield** is an AI-powered financial document forensics platform that ingests bank statements (PDF, scanned images, Excel), extracts structured data using GPT-4o, runs 14+ forensic validation checks, builds knowledge graphs, and provides a human-in-the-loop review workflow — all with a self-learning correction loop that improves accuracy over time.

### The Problem
Manual financial document verification is slow, error-prone, and easily fooled by sophisticated fraud. Banks and auditors spend significant time cross-checking statements, spotting anomalies, and verifying authenticity.

### The Solution
FinShield automates this with:
- **AI extraction** — GPT-4o extracts structured transactions from any format
- **Computer vision** — Image preprocessing (CLAHE, denoising, deskew) handles scanned/photographed documents
- **Forensic analysis** — Benford's Law, structuring detection, velocity analysis, ghost lifestyle detection
- **Knowledge graphs** — Entity resolution and relationship mapping across documents
- **Self-learning** — Correction feedback loop trains the system to avoid repeating mistakes

### What Makes It Unique
1. **Forensic depth** — Goes beyond OCR → validation; applies statistical fraud detection (Benford's Law, structuring patterns, velocity/smurfing)
2. **Evidence bridging** — Links PDF source regions to extracted transactions for audit trails
3. **Multi-format resilience** — Handles clean PDFs, photographed documents, Excel bank statements, OCR garbage
4. **Self-improving** — Every human correction feeds back into the extraction prompt, reducing future errors

---

## 2. System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                              │
│  ┌──────────────────┐  ┌──────────────────────────────────────┐  │
│  │  Flutter Mobile   │  │  React Webapp (Vite + Chakra UI)     │  │
│  │  (Legacy)         │  │  Dashboard │ Ingestion │ Review      │  │
│  │  5 screens        │  │  Document Inspector │ KG Viewer      │  │
│  └───────┬──────────┘  └───────────────┬──────────────────────┘  │
│          │                              │  /api proxy            │
└──────────┼──────────────────────────────┼────────────────────────┘
           │                              │
           ▼                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                     FASTAPI BACKEND (:8000)                       │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │   11 API Routers (28+ endpoints)                             │ │
│  │   documents │ ingestion │ forensics │ review │ dashboard    │ │
│  │   learning │ knowledge │ reports │ batch │ admin │ health   │ │
│  └──────────────────────┬──────────────────────────────────────┘ │
│                          │                                        │
│  ┌───────────────────────┼───────────────────────────────────┐   │
│  │              SERVICE LAYER (11 modules)                     │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐   │   │
│  │  │ Backboard     │ │ Excel        │ │ Validation       │   │   │
│  │  │ Client (GPT-4o│ │ Normalizer   │ │ (14+ forensic    │   │   │
│  │  │ extraction)   │ │ (bank stmt   │ │  checks)         │   │   │
│  │  │ + Learning    │ │  parsing)    │ │                  │   │   │
│  │  └──────────────┘ └──────────────┘ └──────────────────┘   │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐   │   │
│  │  │ File          │ │ Entity       │ │ Knowledge        │   │   │
│  │  │ Preprocess    │ │ Resolution   │ │ Graph            │   │   │
│  │  │ (OpenCV)      │ │ (RapidFuzz)  │ │ (in-memory)      │   │   │
│  │  └──────────────┘ └──────────────┘ └──────────────────┘   │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐   │   │
│  │  │ Quality      │ │ Layout       │ │ Storage          │   │   │
│  │  │ Scoring      │ │ Detection    │ │ (Filesystem)     │   │   │
│  │  └──────────────┘ └──────────────┘ └──────────────────┘   │   │
│  └───────────────────────────────────────────────────────────┘   │
│                          │                                        │
│  ┌───────────────────────┴───────────────────────────────────┐   │
│  │     SQLite via SQLModel / SQLAlchemy  (7 tables)           │   │
│  └───────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│  EXTERNAL: Backboard.io Assistants   │
│  API → OpenAI GPT-4o                 │
└──────────────────────────────────────┘
```

---

## 3. Technology Stack

### Backend
| Technology | Version | Purpose |
|---|---|---|
| **Python** | ≥3.11 (using 3.13) | Core language |
| **FastAPI** | latest | Async REST API framework |
| **Uvicorn** | latest | ASGI server |
| **SQLModel** | latest | ORM (SQLAlchemy + Pydantic hybrid) |
| **SQLAlchemy** | latest | Database engine & migrations |
| **SQLite** | built-in | Relational database |
| **httpx** | latest | Async HTTP client (for Backboard API) |
| **Pydantic Settings** | latest | Configuration management from .env |
| **OpenCV (cv2)** | latest | Image preprocessing pipeline |
| **Pillow** | latest | Image format handling |
| **NumPy** | latest | Numerical operations |
| **pytesseract** | latest | OCR fallback engine |
| **openpyxl** | latest | Excel file parsing |
| **RapidFuzz** | latest | Fuzzy string matching for entity resolution |
| **python-dateutil** | latest | Date parsing |
| **python-multipart** | latest | File upload handling |

### React Webapp
| Technology | Version | Purpose |
|---|---|---|
| **React** | 18.3.1 | UI framework |
| **TypeScript** | 5.5.4 | Type-safe JavaScript |
| **Vite** | 5.4 | Build tool + dev server |
| **Chakra UI** | 2.8.2 | Component library |
| **React Query** | 5.56 | Server state management + caching |
| **Axios** | 1.7 | HTTP client |
| **Recharts** | 2.12 | Data visualization (Bar, Pie, Line, Sankey) |
| **react-force-graph-2d** | 1.29 | Knowledge graph visualization |
| **react-pdf** | 9.1 | PDF document viewer |
| **pdfjs-dist** | 4.7 | PDF rendering engine |
| **Framer Motion** | 11.0 | Animations |
| **React Router** | 6.28 | Client-side routing |
| **canvas-confetti** | 1.9 | Celebration effects on actions |

### Flutter Mobile (Legacy)
| Technology | Version | Purpose |
|---|---|---|
| **Flutter** | stable | Cross-platform mobile framework |
| **Dart** | stable | Language |
| **fl_chart** | 0.66 | Dashboard charts |
| **file_picker** | 10.3 | Document upload |
| **google_fonts** | 6.1 | Typography (Outfit) |
| **animate_do** | 3.1 | Entry animations |

### Infrastructure
| Technology | Purpose |
|---|---|
| **Docker / Docker Compose** | Container deployment |
| **Backboard.io** | LLM Assistants API gateway → OpenAI GPT-4o |
| **Git / GitHub** | Version control |

---

## 4. Key Algorithms & Techniques

### 4.1 Benford's Law Analysis
**What:** A statistical test based on the observation that in naturally occurring datasets, the leading digit `d` appears with frequency `log10(1 + 1/d)`. Fraudulent or fabricated numbers typically fail this distribution.

**Implementation:** Extracts leading digits from all transaction amounts, computes observed frequency distribution, compares against Benford's theoretical distribution. Deviation beyond threshold flags the document.

**Where used:** `validation.py` (forensic check), `DashboardPage.tsx` (aggregate chart), `DocumentReviewPage.tsx` (per-document chart)

### 4.2 Structuring Detection (Smurfing)
**What:** Detects deliberate splitting of transactions to stay below reporting thresholds (e.g., multiple transactions just under ₹50,000 or $10,000).

**Implementation:** Computes 90th-percentile amount as dynamic threshold. Groups transactions into 1-day windows, counts near-threshold transactions. Flags clusters exceeding configurable limits.

**Where used:** `validation.py` — `_check_structuring()`

### 4.3 Velocity / Smurfing Detection
**What:** Flags unusual transaction velocity — too many transactions in a short time window indicating potential money laundering.

**Implementation:** Groups transactions by date, calculates daily counts, flags days exceeding mean + 2σ (standard deviations).

**Where used:** `validation.py` — `_check_velocity()`

### 4.4 Ghost Lifestyle Detection
**What:** Detects accounts that show transactions but exhibit patterns inconsistent with real human behavior (no utility bills, no groceries, only large round-number transfers).

**Implementation:** Analyzes transaction descriptions for lifestyle categories. Flags accounts with zero lifestyle-category matches despite having significant transaction volume.

**Where used:** `validation.py` — `_check_ghost_lifestyle()`

### 4.5 CLAHE Image Enhancement
**What:** Contrast Limited Adaptive Histogram Equalization — improves contrast in scanned/photographed documents without over-amplifying noise.

**Pipeline:** Input image → NL Means Denoising → CLAHE (clip limit 2.0, 8×8 grid) → Skew correction (Hough line detection) → Adaptive Gaussian threshold → Output binary image

**Where used:** `file_preprocess.py`

### 4.6 Fuzzy Entity Resolution
**What:** Links different mentions of the same entity across documents (e.g., "AMAZON" and "Amazon.in" → same vendor).

**Implementation:** Uses RapidFuzz library with 90% similarity threshold. Resolves across 9 entity types: vendor, bank, employer, employee, payer, payee, biller, account_holder, institution.

**Where used:** `entity_resolution.py`, consumed by Knowledge Graph builder

### 4.7 Self-Learning Correction Loop
**What:** Human corrections feed back into the AI extraction system, improving future accuracy.

**Flow:**
1. Human submits a correction (field + old value + new value)
2. Correction stored in DB with document context
3. Corrections clustered by field name
4. When threshold met (≥100 corrections OR ≥10% error rate), learning trigger fires
5. Correction patterns injected into GPT-4o extraction prompt as "learned rules"
6. Backboard.io thread memory also updated with corrections for thread-level learning

**Where used:** `learning.py`, `backboard_learning.py`, `review.py` (API)

### 4.8 Multi-Currency Support
**What:** Automatic currency detection with per-currency forensic thresholds.

**Supported currencies (10):** INR, USD, EUR, GBP, JPY, AED, SGD, AUD, CAD, CNY

**Implementation:** Excel normalizer uses a voting system across amount columns to detect currency. Each currency has a custom forensic profile with adjusted structuring thresholds (e.g., INR ₹50,000 vs USD $10,000).

**Where used:** `excel_normalizer.py` (detection), `validation.py` (thresholds)

### 4.9 Balance Continuity Verification
**What:** Cross-checks that previous statement's closing balance equals current statement's opening balance. Detects doctored or missing statements.

**Where used:** `validation.py` — `_check_balance_continuity()`

### 4.10 Quality Scoring
**What:** Composite image quality assessment to warn users about poor-quality uploads.

**Formula:** `Q = 0.4 × blur_score + 0.3 × brightness_score + 0.3 × contrast_score`

- **Blur:** Laplacian variance (higher = sharper)
- **Brightness:** Mean pixel intensity distance from optimal (127.5)
- **Contrast:** Standard deviation of pixel intensities

**Where used:** `quality.py`

---

## 5. Feature Inventory

### 5.1 Document Ingestion
- **Supported formats:** PDF, PNG, JPG, JPEG, WEBP, TIFF, XLSX
- **Bulk upload:** Multi-file drag-and-drop ingestion
- **Quality check:** Automatic blur/brightness/contrast scoring before AI processing
- **Image enhancement:** OpenCV pipeline for scanned documents
- **OCR fallback:** If AI extraction fails, falls back to Tesseract OCR

### 5.2 AI-Powered Data Extraction
- **Engine:** GPT-4o via Backboard.io Assistants API
- **Extracts:** Document type, holder name, account number, institution, period, currency, transactions (date, description, amount, balance, category)
- **Confidence scoring:** Per-field confidence levels
- **Multi-strategy upload:** Tries file attachment first, falls back to base64 in message

### 5.3 Forensic Validation Engine (14+ checks)
| # | Check | Description |
|---|---|---|
| 1 | Benford's Law | Leading digit distribution analysis |
| 2 | Structuring | Near-threshold transaction clustering |
| 3 | Velocity | Unusual daily transaction counts (>mean + 2σ) |
| 4 | Smurfing | Multiple just-below-limit transactions |
| 5 | Ghost Lifestyle | No lifestyle spending patterns |
| 6 | Synthetic | Fabricated patterns (perfectly sequential, identical amounts) |
| 7 | Balance Continuity | Opening ≠ previous closing balance |
| 8 | Date Sequence | Non-chronological transaction ordering |
| 9 | Duplicate Detection | Identical transactions within timeframe |
| 10 | Round Number | Excessive round-number transactions |
| 11 | Weekend/Holiday | Unusual weekend transaction patterns |
| 12 | Cross-Statement | Multi-document consistency checks |
| 13 | Missing Periods | Gaps in statement coverage |
| 14 | Currency Threshold | Per-currency structuring limits |

### 5.4 Knowledge Graph
- **Node types:** Document, Account, Balance, Counterparty (top 10 by frequency)
- **Entity resolution:** Fuzzy matching across documents (9 entity types)
- **Visualization:** Interactive 2D force-directed graph with color-coded nodes and legend

### 5.5 Human-in-the-Loop Review
- **Review queue:** Filterable/searchable list of documents needing review
- **Triage cards:** Top 3 priority items surfaced for quick action
- **Actions:** Approve, Reject, Re-analyze, Submit correction
- **Evidence bridge:** Click a transaction → highlights source location in PDF
- **"Lie Detector":** Binary integrity verdict (VERIFIED/FAILURE) based on validation results

### 5.6 Dashboard Analytics
- **KPIs:** Total processed, accuracy rate, pending review, avg processing time
- **Charts:** Benford distribution, anomaly breakdown (type/severity), accuracy by document type, quality distribution, money flow Sankey
- **Learning status:** Correction count, error rate, cluster analysis

### 5.7 Reporting
- **JSON reports:** Machine-readable forensic analysis export
- **HTML reports:** Styled, printable forensic reports with risk assessment
- **Batch reports:** Aggregate reports across multiple documents

### 5.8 Self-Learning System
- **Correction tracking:** Every human correction recorded with timestamp and context
- **Clustering:** Groups corrections by field to identify systematic errors
- **Trigger thresholds:** Auto-fires learning when ≥100 corrections or ≥10% error rate
- **Prompt injection:** Learned patterns appended to GPT-4o extraction prompts
- **Thread memory:** Corrections pushed to Backboard.io thread for conversation-level learning

### 5.9 Batch Operations
- **Batch re-analysis:** Re-run forensic checks on all documents without re-uploading
- **Rule configuration:** Customize forensic rule sensitivity per deployment
- **History management:** Clear all data for fresh start

---

## 6. Data Flow — End to End

```
                            USER
                              │
                    Upload document(s)
                              │
                              ▼
                    ┌─────────────────┐
                    │  FILE RECEPTION  │
                    │  (FastAPI)       │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │  Image?  │  │  PDF?    │  │  Excel?  │
        └────┬─────┘  └────┬─────┘  └────┬─────┘
             │              │              │
             ▼              │              ▼
     ┌───────────────┐      │      ┌───────────────┐
     │ Quality Score │      │      │ Excel         │
     │ (blur/bright/ │      │      │ Normalizer    │
     │  contrast)    │      │      │ (header detect│
     └───────┬───────┘      │      │  currency,    │
             │              │      │  clean OCR)   │
             ▼              │      └───────┬───────┘
     ┌───────────────┐      │              │
     │ Image Enhance │      │              │
     │ (CLAHE,       │      │              │
     │  denoise,     │      │              │
     │  deskew)      │      │   ┌──────────┘
     └───────┬───────┘      │   │
             │              │   │
             └──────────────┼───┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │  AI EXTRACTION      │
                 │  (GPT-4o via        │
                 │   Backboard.io)     │
                 │                     │
                 │  + Learned patterns │
                 │    injected into    │
                 │    prompt           │
                 └──────────┬──────────┘
                            │
              Structured JSON (type, holder,
              account #, transactions, etc.)
                            │
                            ▼
                 ┌─────────────────────┐
                 │  FORENSIC ENGINE    │
                 │  14+ validation     │
                 │  checks             │
                 │  (Benford, struct., │
                 │   velocity, ghost,  │
                 │   balance, etc.)    │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │  ENTITY RESOLUTION  │
                 │  (RapidFuzz fuzzy   │
                 │   matching, 9 types)│
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │  KNOWLEDGE GRAPH    │
                 │  (Document, Account,│
                 │   Balance, Counter- │
                 │   party nodes)      │
                 └──────────┬──────────┘
                            │
                            ▼
              ┌──────────────────────────┐
              │  DATABASE (SQLite)        │
              │  Document + Transaction + │
              │  Anomaly + Entity records │
              └──────────────┬───────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
       ┌──────────┐  ┌──────────┐  ┌──────────┐
       │Dashboard │  │ Review   │  │ Reports  │
       │ Charts & │  │ Queue    │  │ JSON/HTML│
       │ Analytics│  │ + Detail │  │ Export   │
       └──────────┘  └────┬─────┘  └──────────┘
                          │
                   Human correction
                          │
                          ▼
              ┌──────────────────────┐
              │  LEARNING LOOP       │
              │  Cluster → Threshold │
              │  → Inject into       │
              │  GPT-4o prompt       │
              └──────────────────────┘
```

---

## 7. Backend Deep Dive

### 7.1 Service Layer (~2,549 lines)

| Service | Lines | Responsibility |
|---|---|---|
| `backboard_client.py` | ~514 | Async GPT-4o extraction with retry, OCR fallback, learned pattern injection |
| `excel_normalizer.py` | ~590 | Bank statement Excel parsing with header detection, currency voting, OCR cleanup |
| `validation.py` | ~498 | 14+ forensic checks with multi-currency threshold profiles |
| `knowledge_graph.py` | ~330 | Pydantic-schema KG, in-memory store, node/edge builder |
| `backboard_learning.py` | ~190 | Correction→Backboard feedback, field clustering, cooldown sync |
| `learning.py` | ~120 | Correction clustering, threshold triggers, background sync |
| `file_preprocess.py` | ~105 | OpenCV pipeline: denoise → CLAHE → deskew → threshold |
| `entity_resolution.py` | ~76 | RapidFuzz fuzzy matching (threshold 90), 9 entity types |
| `quality.py` | ~55 | Composite quality score: blur + brightness + contrast |
| `layout.py` | ~53 | Morphological line detection for tables, header density |
| `storage.py` | ~18 | Filesystem storage at `backend/storage/{doc_id}/` |

### 7.2 API Layer (~2,113 lines)

| Router | Lines | Key Endpoints |
|---|---|---|
| `ingestion.py` | ~453 | POST /ingestion/documents (bulk pipeline) |
| `reports.py` | ~424 | JSON + styled HTML forensic reports |
| `batch.py` | ~347 | Rule CRUD, batch re-analysis |
| `review.py` | ~233 | Queue, approve, reject, correct, reanalyze |
| `dashboard.py` | ~183 | Metrics with Benford/Sankey/accuracy data |
| `forensics.py` | ~164 | Anomaly summaries, transaction lists |
| `admin.py` | ~152 | Learning sync, health, data purge |
| `documents.py` | ~59 | Single doc analyze, get (with KG rebuild), file serve |
| `knowledge.py` | ~53 | KG graph/entity/overview |
| `learning.py` | ~20 | Clusters, manual trigger |
| `health.py` | ~17 | Health check |

### 7.3 Infrastructure (~194 lines)

| File | Lines | Purpose |
|---|---|---|
| `models.py` | ~100 | 7 SQLModel tables |
| `config.py` | ~81 | Pydantic-settings, .env loader |
| `session.py` | ~63 | Engine setup, auto-migration for missing columns |

---

## 8. React Webapp Deep Dive (~3,300 lines)

### 8.1 Pages

| Page | Lines | Features |
|---|---|---|
| **DocumentReviewPage** | ~1,416 | PDF viewer, evidence bridge, Lie Detector integrity panel, Benford/Sankey/balance charts, KG viewer, correction form, transaction tables |
| **DashboardPage** | ~813 | 5 KPI cards, 7+ charts (Benford, Sankey, accuracy, quality, severity, anomaly types), learning status, batch re-analysis, clear history |
| **IngestionPage** | ~360 | Drag-drop upload, debug console, results table with confidence gauges, batch timing |
| **ReviewQueuePage** | ~290 | Search/filter, triage cards (top 3), full queue table, approve/reject with confetti |

### 8.2 State Management
- **Server state:** React Query (`@tanstack/react-query`) — automatic caching, background refetching, optimistic updates via `invalidateQueries`
- **Local state:** React `useState` for UI-only state (filters, search, modals)
- **No global client state store** — all persistent data lives server-side

### 8.3 UI Design System: "Obsidian Aurora"
- Dark theme with radial gradient background
- Glassmorphism cards with backdrop blur
- Color palette: obsidian (gray-900 base), aurora (emerald), nebula (purple), glow (brand accents)
- Inter font family
- Custom glow shadows on interactive elements

---

## 9. Flutter Mobile App (~2,003 lines, Legacy)

Fully functional mobile app with 5 screens, dark glassmorphism theme ("neon-on-dark"), animated floating blob background. Uses `setState` for state management and `fl_chart` for dashboard charts.

**Status:** Legacy — the React webapp now has feature parity and exceeds Flutter in functionality (Knowledge Graph, PDF viewer, Benford/Sankey charts, learning system, batch operations).

---

## 10. Database Schema

```sql
-- 7 tables in SQLite via SQLModel

Document          -- id, filename, type, status, confidence, currency,
                  -- holder_name, institution, account_no, period, etc.

Transaction       -- id, document_id (FK), date, description, amount,
                  -- balance, category, is_anomaly, anomaly_reason,
                  -- merchant_normalized

Anomaly           -- id, document_id (FK), type, severity, description,
                  -- details (JSON), resolved, resolved_by

Correction        -- id, document_id (FK), field, old_value, new_value,
                  -- created_at

Entity            -- id, name, type, normalized_name, source_document_id

DocumentEntity    -- id, document_id (FK), entity_id (FK), relationship

LearningEvent     -- id, event_type, details, created_at
```

---

## 11. API Surface

### 28+ REST Endpoints

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/health` | Health check |
| `POST` | `/api/documents/analyze` | Single document analysis |
| `GET` | `/api/documents/{id}` | Get document with KG rebuild |
| `GET` | `/api/documents/{id}/file` | Serve original file |
| `POST` | `/api/ingestion/documents` | Bulk multi-file ingestion |
| `GET` | `/api/dashboard/metrics` | Dashboard KPIs + chart data |
| `GET` | `/api/forensics/anomalies/summary` | Anomaly aggregate stats |
| `GET` | `/api/forensics/anomalies/{doc_id}` | Per-document anomalies |
| `GET` | `/api/forensics/documents/{doc_id}/transactions` | Transaction list |
| `GET` | `/api/forensics/status/{batch_id}` | Batch ingestion status |
| `GET` | `/api/review/queue` | Pending review queue |
| `DELETE` | `/api/review/queue` | Clear review history |
| `POST` | `/api/review/{id}/approve` | Approve document |
| `POST` | `/api/review/{id}/reject` | Reject document |
| `POST` | `/api/review/{id}/reanalyze` | Re-run analysis |
| `POST` | `/api/review/{id}/correct` | Submit field correction |
| `GET` | `/api/review/history` | Review action history |
| `GET` | `/api/batch/rules` | Get forensic rules config |
| `PUT` | `/api/batch/rules` | Update forensic rules |
| `POST` | `/api/batch/reanalyze` | Batch re-analyze all docs |
| `POST` | `/api/batch/reanalyze/{id}` | Re-analyze single doc |
| `GET` | `/api/learning/errors/clusters` | Correction clusters |
| `POST` | `/api/learning/triggers` | Manual learning trigger |
| `GET` | `/api/knowledge/documents/{id}` | Document KG |
| `GET` | `/api/knowledge/entities` | All entities |
| `GET` | `/api/knowledge/graph/overview` | Full KG overview |
| `GET` | `/api/reports/{id}` | JSON forensic report |
| `GET` | `/api/reports/{id}/html` | Styled HTML report |
| `GET` | `/api/reports/batch/{batch_id}` | Batch report |
| `POST` | `/api/admin/learning/sync` | Force learning sync |
| `GET` | `/api/admin/learning/status` | Learning system status |
| `GET` | `/api/admin/health` | Detailed health check |
| `DELETE` | `/api/admin/history` | Purge all data |

---

## 12. Infrastructure & DevOps

### Docker
- **Production:** Multi-stage Dockerfile with Python 3.11-slim base
- **Development:** Docker Compose with hot-reload (volume mount, `--reload` flag)
- **Network:** Isolated `finshield-network`
- **Port:** 8000 (backend), 5173 (Vite dev server)

### Environment Configuration
- `.env` file with Pydantic Settings auto-loading
- Key configs: `BACKBOARD_API_KEY`, `BACKBOARD_ASSISTANT_ID`, `DATABASE_URL`, `REVIEW_THRESHOLD`, `OCR_ENABLED`

### Development Workflow
- Backend: `python -m app.scripts.dev` (auto-reload)
- Webapp: `npm run dev` (Vite with HMR, API proxy)
- Flutter: `flutter run`

---

## 13. Codebase Metrics

| Component | Files | Lines (approx.) |
|---|---|---|
| Backend Services | 11 | ~2,549 |
| Backend API Routes | 11 | ~2,113 |
| Backend Infrastructure | 3 | ~194 |
| **Backend Total** | **25** | **~4,856** |
| React Webapp | 9 | ~3,300 |
| Flutter Mobile | 12 | ~2,003 |
| Config/Infra | 5+ | ~300 |
| **Grand Total** | **~51** | **~10,459** |

### Dependency Count
- **Python:** 17 direct dependencies
- **npm:** 16 direct dependencies + 3 dev
- **Dart/Flutter:** 15 declared dependencies (6 actively used)

---

## 14. Security Considerations

### Current Implementation
- **CORS:** Configured with allow-all origins for development (should be restricted for production)
- **Input validation:** Pydantic models validate all API inputs
- **File type checking:** MIME type + extension validation on upload
- **SQL injection:** Protected by SQLModel/SQLAlchemy parameterized queries
- **No authentication:** Currently open (suitable for local/demo deployment)

### Production Recommendations
- Add JWT/OAuth2 authentication
- Restrict CORS to specific domains
- Add rate limiting
- Encrypt SQLite database or migrate to PostgreSQL
- Add audit logging for compliance
- Implement file scanning for malware
- Add HTTPS/TLS termination

---

## 15. Scalability Discussion

### Current Architecture (Suitable for: Demo / Single-user / Small team)
- **SQLite:** Single-file database, handles up to ~100K documents easily
- **In-memory KG:** Rebuilt on request, no persistent graph DB
- **Synchronous processing:** Documents processed inline during upload
- **Single-server:** One uvicorn instance

### Scale-up Path
| Bottleneck | Solution |
|---|---|
| SQLite concurrency | Migrate to PostgreSQL |
| AI extraction speed | Background job queue (Celery + Redis) |
| Knowledge graph size | Move to Neo4j or ArangoDB |
| File storage | Object storage (S3 / MinIO) |
| Concurrent users | Horizontal scale with load balancer |
| Real-time updates | WebSocket push for processing status |

### What's Already Scalable
- **Stateless API:** No server-side sessions, easy to replicate
- **Async HTTP:** `httpx` async client for non-blocking AI calls
- **Modular services:** Each service is independently testable/replaceable
- **Docker-ready:** Container deployment from day one

---

## 16. Differentiators & Novel Techniques

### 1. Forensic Depth Beyond OCR
Most document AI tools stop at extraction. FinShield goes further with 14+ statistical forensic checks including Benford's Law, structuring detection, and ghost lifestyle analysis — techniques used by actual financial investigators.

### 2. Evidence Bridging
The "Lie Detector" panel and PDF evidence bridge create an auditable link between extracted data and source document locations — critical for regulatory compliance.

### 3. Self-Learning Loop
The correction → clustering → prompt injection cycle creates a system that genuinely improves with use. Most tools require manual retraining; FinShield adapts automatically.

### 4. Multi-Format Resilience
The CV pipeline (CLAHE, denoising, deskew) + OCR fallback + Excel normalizer means the system handles real-world document quality — not just clean PDFs.

### 5. Knowledge Graph Entity Resolution
Fuzzy matching across documents builds cross-document intelligence. The KG visualization reveals patterns invisible in flat transaction tables.

### 6. Multi-Currency Forensics
Per-currency structuring thresholds (10 currencies) demonstrate domain sophistication — ₹50,000 (India) vs $10,000 (USA) vs ¥1,000,000 (Japan) reporting thresholds.

---

## 17. Anticipated Technical Questions & Answers

### Q: How does the AI extraction work?
**A:** We use GPT-4o via the Backboard.io Assistants API. Documents are uploaded to a persistent Backboard thread. The AI receives a structured prompt requesting specific fields (document type, holder name, transactions, etc.) and returns structured JSON. We have multi-strategy upload (file attachment first, base64 fallback) and exponential backoff retry. If AI extraction fails entirely, we fall back to Tesseract OCR. The system also injects learned correction patterns into the prompt, so accuracy improves over time.

### Q: What happens with poor quality scans?
**A:** Before AI processing, every image goes through an OpenCV enhancement pipeline: Fast NL Means denoising → CLAHE contrast enhancement (clip limit 2.0, 8×8 grid) → Hough-line-based skew correction → adaptive Gaussian thresholding. We also compute a quality score (40% blur via Laplacian variance, 30% brightness, 30% contrast) and warn users about low-quality uploads.

### Q: How does Benford's Law work for fraud detection?
**A:** Benford's Law observes that in natural datasets, ~30.1% of numbers start with "1", ~17.6% with "2", down to ~4.6% with "9". Fabricated or manipulated financial data typically deviates from this distribution. We extract leading digits from all transaction amounts, compute the observed distribution, and compare it against Benford's expected frequencies. Significant deviation flags the document for review.

### Q: How does the learning loop work?
**A:** When a reviewer corrects a field (e.g., changes "savings" to "current" for account_type), the correction is stored with full context. Corrections are clustered by field name. When we hit a threshold (≥100 corrections or ≥10% error rate for a field), the system generates "learned rules" that are appended to the GPT-4o extraction prompt for future documents. Additionally, corrections are pushed to the Backboard.io thread memory, providing conversation-level context. This creates a dual-learning mechanism: prompt-level rules + thread-level memory.

### Q: Why SQLite instead of PostgreSQL?
**A:** SQLite was chosen for zero-configuration deployment — no database server to install or manage. It's embedded, file-based, and handles the current scale easily. The codebase uses SQLModel (SQLAlchemy under the hood), so migrating to PostgreSQL is a one-line configuration change (`DATABASE_URL` from `sqlite:///` to `postgresql://`).

### Q: How do you handle multiple currencies?
**A:** The Excel normalizer uses a voting system across amount columns to detect currency. We maintain 10 currency profiles (INR, USD, EUR, GBP, JPY, AED, SGD, AUD, CAD, CNY), each with calibrated structuring thresholds that match real regulatory reporting limits. For example, India's ₹50,000 threshold vs USA's $10,000 threshold for suspicious transaction reporting.

### Q: What's the entity resolution approach?
**A:** We use RapidFuzz (a high-performance fuzzy string matching library) with a 90% similarity threshold. When entities are extracted from documents, they're compared against all existing entities across 9 category types (vendor, bank, employer, payee, etc.). Matches above threshold are linked, allowing the Knowledge Graph to show cross-document relationships even when entity names vary slightly.

### Q: How would you scale this?
**A:** The architecture is designed for horizontal scaling. Immediate steps: (1) Swap SQLite for PostgreSQL for concurrent access, (2) Add Celery + Redis for background document processing, (3) Move file storage to S3/MinIO, (4) Add a Neo4j graph database for the Knowledge Graph. The API is already stateless, Docker-ready, and uses async HTTP clients — so horizontal replication behind a load balancer is straightforward.

### Q: What's the tech stack summary?
**A:** Python/FastAPI backend with 11 service modules and 28+ API endpoints. React/TypeScript webapp with Chakra UI and Recharts for visualization. GPT-4o for AI extraction, OpenCV for image preprocessing, RapidFuzz for entity resolution, SQLite for storage. Docker Compose for deployment. ~10,500 lines of code across ~51 files.

### Q: How do you ensure extraction accuracy?
**A:** Multiple layers: (1) Image preprocessing improves input quality before AI sees it, (2) Structured prompts with explicit field definitions minimize hallucination, (3) Forensic validation catches statistical impossibilities in the output, (4) Human review catches remaining errors, (5) The self-learning loop feeds corrections back into future prompts, continuously improving accuracy.

### Q: What about compliance and audit trails?
**A:** Every document has a full lifecycle tracked: upload timestamp, processing time, AI confidence score, validation results, review actions (approve/reject/correct), correction history, and anomaly records. The HTML report generator creates printable forensic summaries suitable for regulatory submission. The evidence bridge links extracted data back to source document locations for verification.

---

*Generated for FinShield v2.0.0 — Last updated: February 2025*
