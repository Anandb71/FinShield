// Shared TypeScript types that mirror the new backend APIs.

export type ValidationSummary = {
  valid: boolean;
  errors: Record<string, unknown>[];
  warnings: Record<string, unknown>[];
};

export type Classification = {
  type: string;
  confidence: number;
  language?: string;
  image_quality_score?: number | null;
};

export type DocumentAnalysis = {
  document_id: string;
  filename: string;
  classification: Classification;
  layout?: Record<string, boolean | null>;
  quality_metrics?: Record<string, unknown>;
  extracted_fields: Record<string, unknown>;
  validation: ValidationSummary;
  consistency_check?: Record<string, unknown>;
  status: string;
  knowledge_graph?: KnowledgeGraphSlice | null;
};

export type IngestionSummary = {
  document_id?: string;
  filename?: string;
  doc_type?: string;
  confidence?: number;
  status: string;
  error?: string;
  batch_id?: string;
  processing_time_ms?: number;
  anomalies_count?: number;
  layout?: Record<string, boolean | null>;
  quality_metrics?: Record<string, unknown>;
  debug_log?: string[];
  review_reasons?: string[];
  validation?: {
    errors?: Record<string, unknown>[];
    warnings?: Record<string, unknown>[];
  };
};

export type KnowledgeGraphNode = {
  id: string;
  type: string;
  properties: Record<string, unknown>;
};

export type KnowledgeGraphEdge = {
  id: string;
  type: string;
  source_id: string;
  target_id: string;
  properties: Record<string, unknown>;
};

export type KnowledgeGraphSlice = {
  document_id: string;
  nodes: KnowledgeGraphNode[];
  edges: KnowledgeGraphEdge[];
};

export type DashboardMetrics = {
  overview: {
    total_documents_processed: number;
    total_corrections: number;
    error_rate: number;
    avg_processing_time_ms: number | null;
    max_processing_time_ms: number | null;
    avg_quality_score?: number | null;
  };
  anomaly_overview?: {
    total_anomalies: number;
    by_type: Record<string, number>;
    by_severity: Record<string, number>;
    density: number;
  };
  knowledge_graph?: {
    documents: number;
    entities: number;
  };
  accuracy_by_type: Record<
    string,
    {
      accuracy: number;
      count: number;
    }
  >;
  quality_distribution?: {
    low: number;
    medium: number;
    high: number;
  };
  status_distribution?: Record<string, number>;
  benford?: {
    digit: number;
    observed: number;
    expected: number;
  }[];
  money_flow?: {
    nodes: { name: string }[];
    links: { source: number; target: number; value: number }[];
    suspicious_threshold?: number;
  };
  top_error_fields: { field: string; count: number }[];
};

export type ReviewQueueItem = {
  document_id: string;
  filename: string;
  doc_type: string;
  confidence: number | null;
  status: string;
  validation_errors: Record<string, unknown>[];
  validation_warnings: Record<string, unknown>[];
};

export type AnomalyRecord = {
  id: number;
  document_id?: string;
  transaction_id: number | null;
  type: string;
  severity: "critical" | "warning" | "info";
  description: string;
  details: Record<string, unknown> | null;
  row_index: number | null;
  created_at?: string;
};

export type TransactionRecord = {
  id: number;
  document_id?: string;
  row_index: number;
  date: string | null;
  description: string | null;
  amount: number | null;
  type: string | null;
  balance_after: number | null;
  merchant_normalized: string | null;
  category: string | null;
  is_anomaly: boolean;
  anomaly_tags: string | null;
};

export type BatchStatus = {
  batch_id: string;
  total: number;
  completed: number;
  failed: number;
  in_progress: number;
  documents: {
    document_id: string;
    filename: string;
    status: string;
  }[];
};

