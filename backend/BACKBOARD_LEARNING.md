# Backboard Learning System

## How Backboard Learns from Your Documents

### 🔄 Automatic Learning (Built-in)

**Every document you upload automatically improves Backboard:**

1. **Knowledge Graph Growth**
   - Each document is indexed in Backboard's knowledge graph
   - Entities (vendors, employers, accounts) are extracted and linked
   - Relationships between documents are established

2. **Pattern Recognition**
   - As you upload more invoices from "Acme Corp", Backboard learns:
     - Typical invoice structure from this vendor
     - Common amounts and payment terms
     - Expected fields and formats

3. **Better RAG Queries**
   - More documents = better context for queries
   - Cross-document consistency checks become more accurate
   - Entity resolution improves (e.g., "Acme" vs "Acme Corp" → same vendor)

---

## 🎓 Enhanced Learning with Human Corrections

**We've added a feedback loop to accelerate Backboard's learning:**

### When You Submit a Correction

```http
POST /api/review/{doc_id}/correct
{
  "document_id": "uuid",
  "field_name": "vendor_name",
  "original_value": "Acme Crp",  // Wrong extraction
  "corrected_value": "Acme Corp"  // Correct value
}
```

**What Happens:**

1. **Correction Stored Locally**
   - Saved in learning loop database
   - Used for error clustering

2. **Fed Back to Backboard** ✨
   - Creates a "corrected version" document in knowledge graph
   - Stores correction metadata
   - Future queries can reference these corrections

3. **Learning Pattern Created**
   - When 3+ similar errors occur, creates a learning example
   - Stored in Backboard as: "Common error pattern for vendor_name"

---

## 📊 Learning Workflow

```
User uploads invoice
    ↓
Backboard extracts: "vendor_name": "Acme Crp" (wrong)
    ↓
User corrects to: "Acme Corp"
    ↓
System stores correction locally
    ↓
System creates correction document in Backboard:
  "Document X had vendor_name corrected from 'Acme Crp' to 'Acme Corp'"
    ↓
Next time Backboard sees "Acme Crp", it can reference this correction
    ↓
After 3+ similar corrections, creates learning pattern:
  "Common mistake: 'Acme Crp' should be 'Acme Corp'"
```

---

## 🔧 API Endpoints

### 1. Submit Correction (Auto-learns)
```http
POST /api/review/{doc_id}/correct
```
Automatically feeds correction to Backboard.

### 2. Manual Learning Sync
```http
POST /api/admin/learning/sync
```
Manually trigger creation of learning patterns from error clusters.

### 3. View Error Clusters
```http
GET /api/review/errors/clusters
```
See which fields have the most corrections.

---

## 🎯 Benefits

### Immediate Benefits
- **Cross-document consistency**: Backboard can reference past documents
- **Entity resolution**: Links "Acme Corp" across 100s of invoices
- **Contradiction detection**: Finds conflicting information

### Long-term Benefits (with corrections)
- **Improved accuracy**: Learns from mistakes
- **Pattern recognition**: Identifies common extraction errors
- **Self-correction**: Future extractions reference past corrections

---

## 📈 Example Learning Scenario

**Month 1**: Upload 50 invoices
- Backboard learns typical invoice structures
- Builds vendor knowledge graph

**Month 2**: Submit 20 corrections
- System identifies "vendor_name" has 15 errors
- Creates learning pattern for this field
- Stores corrected examples in Backboard

**Month 3**: Upload 50 more invoices
- Backboard queries reference past corrections
- Extraction accuracy improves
- Fewer corrections needed

---

## 🔄 Retraining Triggers

System automatically triggers retraining when:
- **100+ corrections** accumulated
- **Error rate > 10%**

When triggered:
- Logs warning
- Creates comprehensive learning examples
- Syncs all patterns to Backboard

---

## 💡 Best Practices

1. **Submit corrections promptly**
   - The sooner you correct, the sooner Backboard learns

2. **Review error clusters regularly**
   - `GET /api/review/errors/clusters`
   - Focus on high-frequency errors

3. **Manually sync learning patterns**
   - `POST /api/admin/learning/sync`
   - Run weekly or after major correction batches

4. **Monitor dashboard metrics**
   - `GET /api/dashboard/metrics`
   - Track accuracy improvements over time

---

## 🚀 Future Enhancements

- **Active learning**: Backboard requests clarification on low-confidence extractions
- **Transfer learning**: Apply patterns from one document type to similar types
- **Automated retraining**: Trigger Backboard model updates based on corrections
