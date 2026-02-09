# Frontend Integration Guide - FinShield Document Intelligence

## 🎯 What Was Built

A **complete ML document intelligence backend** using Backboard.io that:
- Auto-classifies documents (invoice, bank statement, payslip, contract)
- Extracts structured data with OCR and layout detection
- Validates data with business logic
- Learns from human corrections
- Provides quality metrics dashboard

---

## 🔌 API Endpoints for Frontend

### Base URL
```
http://localhost:8000/api
```

---

## 📤 1. Document Upload & Analysis

**Primary endpoint (single document)**: `POST /api/documents/analyze`

**Request**:
```javascript
const formData = new FormData();
formData.append('file', pdfFile); // PDF file from file picker

const response = await fetch('http://localhost:8000/api/documents/analyze', {
  method: 'POST',
  body: formData
});

const result = await response.json();
```

**Response**:
```json
{
  "document_id": "uuid-here",
  "filename": "invoice.pdf",
  "classification": {
    "type": "invoice",
    "confidence": 0.95
  },
  "extracted_fields": {
    "invoice_number": "INV-001",
    "vendor_name": "Acme Corp",
    "total_amount": 50000,
    "invoice_date": "2024-01-15",
    "line_items": [...]
  },
  "layout": {
    "tables": [...],
    "headers": [...]
  },
  "validation": {
    "valid": true,
    "errors": [],
    "warnings": ["Minor date mismatch"]
  },
  "consistency_check": {
    "consistent": true,
    "explanation": "No conflicts found"
  },
  "processing_time_seconds": 2.3,
  "status": "success"
}
```

---

### Bulk ingestion (new web UI)

The new React-based Reviewer UI uses a bulk-ingestion API that wraps the same
pipeline and stores the results in the shared memory + knowledge graph.

**Endpoint**: `POST /api/ingestion/documents`

**Response (summary per file)**:
```json
{
  "documents": [
    {
      "document_id": "uuid-here",
      "filename": "invoice.pdf",
      "doc_type": "INVOICE",
      "confidence": 0.94,
      "status": "success"
    }
  ]
}
```

## ✏️ 2. Submit Corrections

**Endpoint**: `POST /api/review/{doc_id}/correct`

**Use Case**: User corrects an extracted field

**Request**:
```javascript
const correction = {
  document_id: "uuid-here",
  field_name: "vendor_name",
  original_value: "Acme Crp",      // Wrong extraction
  corrected_value: "Acme Corp",    // Correct value
  corrected_by: "user@example.com"
};

await fetch(`http://localhost:8000/api/review/${docId}/correct`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(correction)
});
```

**Response**:
```json
{
  "status": "success",
  "correction_id": "corr_123",
  "message": "Correction captured and fed to Backboard for learning"
}
```

---

## ✅ 3. Approve Document

**Endpoint**: `POST /api/review/{doc_id}/approve`

**Request**:
```javascript
await fetch(`http://localhost:8000/api/review/${docId}/approve`, {
  method: 'POST'
});
```

**Response**:
```json
{
  "status": "approved",
  "document_id": "uuid-here"
}
```

---

## 📊 4. Dashboard Metrics

**Endpoint**: `GET /api/dashboard/metrics`

**Use Case**: Display extraction quality dashboard

**Request**:
```javascript
const metrics = await fetch('http://localhost:8000/api/dashboard/metrics')
  .then(r => r.json());
```

**Response**:
```json
{
  "overview": {
    "total_documents_processed": 150,
    "total_corrections": 12,
    "error_rate": 0.08,
    "avg_processing_time": 2.1
  },
  "accuracy_by_type": {
    "invoice": {"accuracy": 0.95, "count": 80},
    "bank_statement": {"accuracy": 0.92, "count": 50}
  },
  "error_clusters": {
    "vendor_name": {
      "count": 5,
      "examples": [...]
    }
  },
  "top_error_fields": [
    {"field": "vendor_name", "count": 5},
    {"field": "total_amount", "count": 3}
  ]
}
```

---

## 🔍 5. Review Queue

**Endpoint**: `GET /api/review/queue`

**Use Case**: Get documents needing human review

**Response**:
```json
{
  "queue": [],
  "count": 0,
  "message": "No documents pending review"
}
```

---

## 📈 6. Error Clusters

**Legacy endpoint**: `GET /api/review/errors/clusters`

**Learning-loop endpoint (for analytics)**: `GET /api/learning/errors/clusters`

**Use Case**: View common extraction errors

**Response**:
```json
{
  "clusters": {
    "vendor_name": {
      "count": 15,
      "examples": [
        {"original": "Acme Crp", "corrected": "Acme Corp"}
      ]
    }
  },
  "total_corrections": 25
}
```

---

## 🛠️ Frontend Implementation Examples

### Upload Document Flow

```javascript
// 1. User selects PDF
const handleFileUpload = async (file) => {
  setLoading(true);
  
  const formData = new FormData();
  formData.append('file', file);
  
  try {
    const response = await fetch('http://localhost:8000/api/documents/analyze', {
      method: 'POST',
      body: formData
    });
    
    const result = await response.json();
    
    // 2. Display extracted fields
    setExtractedData(result.extracted_fields);
    setDocumentType(result.classification.type);
    setValidation(result.validation);
    
  } catch (error) {
    console.error('Upload failed:', error);
  } finally {
    setLoading(false);
  }
};
```

### Correction Flow

```javascript
// User edits a field
const handleFieldCorrection = async (fieldName, newValue, originalValue) => {
  const correction = {
    document_id: currentDocId,
    field_name: fieldName,
    original_value: originalValue,
    corrected_value: newValue,
    corrected_by: currentUser.email
  };
  
  await fetch(`http://localhost:8000/api/review/${currentDocId}/correct`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(correction)
  });
  
  // Update UI
  showToast('Correction saved and system is learning!');
};
```

### Dashboard Display

```javascript
// Fetch and display metrics
const DashboardComponent = () => {
  const [metrics, setMetrics] = useState(null);
  
  useEffect(() => {
    fetch('http://localhost:8000/api/dashboard/metrics')
      .then(r => r.json())
      .then(setMetrics);
  }, []);
  
  return (
    <div>
      <h2>Extraction Quality</h2>
      <p>Error Rate: {(metrics?.overview.error_rate * 100).toFixed(1)}%</p>
      <p>Total Documents: {metrics?.overview.total_documents_processed}</p>
      
      <h3>Accuracy by Type</h3>
      {Object.entries(metrics?.accuracy_by_type || {}).map(([type, data]) => (
        <div key={type}>
          {type}: {(data.accuracy * 100).toFixed(1)}% ({data.count} docs)
        </div>
      ))}
    </div>
  );
};
```

---

## 🎨 UI Components to Build

### 1. Document Upload Screen
- File picker for PDF upload
- Loading indicator during analysis
- Progress bar

### 2. Extraction Review Screen
- Display extracted fields in editable form
- Highlight validation errors/warnings
- "Approve" and "Correct" buttons
- Show document classification and confidence

### 3. Dashboard Screen
- Overall metrics (error rate, total docs)
- Accuracy charts by document type
- Top error fields list
- Trend graphs

### 4. Correction Interface
- Inline editing for each field
- Show original vs corrected value
- Submit correction button
- Success feedback

---

## 🔧 Configuration

**Backend URL**: Set in your frontend config
```javascript
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';
```

**CORS**: Already configured in backend to allow all origins during development

---

## 📋 Document Types & Fields

### Invoice
- `invoice_number`, `vendor_name`, `total_amount`, `invoice_date`, `line_items`

### Bank Statement
- `account_number`, `opening_balance`, `closing_balance`, `transactions`

### Payslip
- `employee_name`, `employer_name`, `gross_salary`, `net_salary`, `deductions`

### Contract
- `contract_number`, `parties`, `effective_date`, `terms`

---

## 🚀 Quick Start

1. **Start Backend**:
   ```bash
   cd backend
   uvicorn app.main:app --reload
   ```

2. **Test API**:
   ```bash
   curl -X POST http://localhost:8000/api/documents/analyze \
     -F "file=@invoice.pdf"
   ```

3. **Build Frontend**: Use the endpoints above to integrate with your Flutter/React app

---

## 🎓 Learning System

- Every correction automatically improves the system
- Backboard learns from uploaded documents
- Error patterns are tracked and analyzed
- System triggers retraining at 100+ corrections or >10% error rate

---

## 📞 Support

- API Docs: `http://localhost:8000/docs` (Swagger UI)
- Health Check: `http://localhost:8000/api/v1/health`
