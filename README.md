# 🛡️ FinShield - The Financial Flight Recorder

> **Autonomous, real-time defense system for mobile users that detects financial fraud during live calls and scans contracts for predatory clauses.**

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python](https://img.shields.io/badge/python-3.11+-green.svg)
![Flutter](https://img.shields.io/badge/flutter-3.16+-blue.svg)

---

## 🎯 Mission

FinShield acts as your personal financial bodyguard:

- **📞 Call Shield**: Real-time analysis of phone calls to detect urgency manipulation, fear tactics, and pressure techniques used by scammers
- **📄 Contract Scanner**: Instant detection of predatory clauses, hidden fees, and exploitative terms in financial documents
- **🧠 Context Engine**: Cross-references audio patterns against document analysis for comprehensive threat assessment

---

## 🏗️ Architecture

```
FinShield/
├── backend/          # FastAPI Python service
│   ├── app/
│   │   ├── api/v1/   # Versioned REST endpoints
│   │   ├── services/ # AI service abstractions
│   │   └── core/     # Configuration & security
│   └── Dockerfile
│
├── frontend/         # Flutter mobile app
│   ├── lib/
│   │   ├── core/     # Theme, constants
│   │   ├── features/ # Feature modules
│   │   └── services/ # API clients
│   └── pubspec.yaml
│
└── docker-compose.yml
```

---

## 🚀 Quick Start

### Backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate  # Windows
pip install -e .
python scripts/dev.py
```

API available at: `http://localhost:8000`

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

---

## 🔌 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/health` | GET | Service health check |
| `/api/v1/analyze` | POST | Analyze audio/document for threats |

---

## 🧠 Core Intelligence Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| Audio Analysis | Hotfoot Audio | Real-time intent/urgency detection |
| Document Scanning | Hotfoot Docs | Entity & clause extraction |
| Context Engine | Backboard.io RAG | Cross-reference audio vs documents |

---

## 🎨 Design Philosophy

- **Dark Mode First**: Cyber-security aesthetic with neon accents
- **Privacy Focused**: All processing can run on-device
- **Modular AI**: Plug-and-play service abstractions

---

## 📜 License

MIT License - Built for protection, not profit.

---

<p align="center">
  <strong>🛡️ Your Financial Guardian Angel 🛡️</strong>
</p>
