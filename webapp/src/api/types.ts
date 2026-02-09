// Shared TypeScript types that mirror the new backend APIs.

export type ValidationSummary = {
  valid: boolean;
  errors: string[];
  warnings: string[];
};

export type Classification = {
  type: string;
  confidence: number;
};

export type LayoutFlags = {
  tables: boolean;
  handwritten: boolean;
  stamps: boolean;
  signatures: boolean;
  headers: boolean;
};

export type DocumentAnalysis = {
  document_id: string;
  filename: string;
  classification: Classification;
  extracted_fields: Record<string, unknown>;
  layout: LayoutFlags;
  layout_tags?: string[];
  validation: ValidationSummary;
  processing_time_seconds: number;
  status: string;
  knowledge_graph?: KnowledgeGraphSlice;
};

export type IngestionSummary = {
  document_id?: string;
  filename?: string;
  doc_type?: string;
  confidence?: number;
  status: string;
  error?: string;
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
    avg_processing_time: number;
  };
  knowledge_graph?: {
    total_documents: number;
    node_counts: Record<string, number>;
    edge_counts: Record<string, number>;
  };
  accuracy_by_type: Record<
    string,
    {
      accuracy: number;
      count: number;
    }
  >;
  top_error_fields: { field: string; count: number }[];
};

