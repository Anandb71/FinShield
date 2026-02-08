# Changelog

All notable changes to the "Finsight: Autonomous Auditor" project will be documented in this file.

## [2.0.0] - 2026-02-09

### 🚀 Major Pivot: Forensic Knowledge Graph
- **Rebrand**: Renamed from "FinShield" to **"Finsight"**.
- **New Home**: Replaced list view with **Investigation Board** (Force-Directed Graph).
- **Core Feature**: **Multi-Document Reconciliation** (Invoice vs Bank Statement).

### ✨ New Features
- **Investigation Board**:
  - Interactive Graph with Blue (Docs), Yellow (Entities), and Red (Risks) nodes.
  - Conflict of Interest detection (Red edges).
  - Time Slider for temporal filtering.
- **X-Ray Viewer v2**:
  - **Reconciliation Tab**: Smart Match logic (Exact/Fuzzy) for payment verification.
  - **Learning Loop**: Human-in-the-loop "Force Match" for model retraining.
  - **Status Banners**: "PAYMENT VERIFIED" vs "GHOST INVOICE".
- **Backend**:
  - `ConsistencyEngine`: Cross-document knowledge graph.
  - `ReconciliationEngine`: Payment matching algorithm.

### � Fixes
- Fixed build errors in Graph View algorithm.
- Resolved dependency conflicts (lucide_icons).

---

## [1.0.0] - 2026-02-08 (Archived)
- Initial FinShield release (Text & Audio Intelligence).
