import {
  Badge,
  Box,
  Button,
  Divider,
  FormControl,
  FormLabel,
  Heading,
  HStack,
  Input,
  IconButton,
  SimpleGrid,
  Spinner,
  Stat,
  StatHelpText,
  StatLabel,
  StatNumber,
  Table,
  Tab,
  TabList,
  TabPanel,
  TabPanels,
  Tabs,
  Tbody,
  Td,
  Text,
  Th,
  Thead,
  Tr,
  VStack,
  Switch,
  Icon
} from "@chakra-ui/react";
import { FiChevronLeft, FiChevronRight, FiDownload, FiFileText, FiDatabase } from "react-icons/fi";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useParams } from "react-router-dom";
import { useEffect, useMemo, useRef, useState } from "react";
import ForceGraph3D from "react-force-graph-3d";
import confetti from "canvas-confetti";
import { Document, Page, pdfjs } from "react-pdf";
import {
  Bar,
  BarChart,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Sankey,
  Tooltip as RechartsTooltip,
  XAxis,
  YAxis
} from "recharts";

import { api } from "../api/client";
import type { DocumentAnalysis, AnomalyRecord, TransactionRecord } from "../api/types";

pdfjs.GlobalWorkerOptions.workerSrc = new URL(
  "pdfjs-dist/build/pdf.worker.min.js",
  import.meta.url
).toString();
type CorrectionRequest = {
  field_name: string;
  original_value: string;
  corrected_value: string;
};

export default function DocumentReviewPage() {
  const { docId } = useParams<{ docId: string }>();
  const queryClient = useQueryClient();
  const [correction, setCorrection] = useState<CorrectionRequest>({
    field_name: "",
    original_value: "",
    corrected_value: ""
  });
  const [searchTerm, setSearchTerm] = useState("");
  const [minAmount, setMinAmount] = useState("");
  const [showAnomalies, setShowAnomalies] = useState(false);
  const [selectedTxnIndex, setSelectedTxnIndex] = useState<number | null>(null);
  const [selectedNode, setSelectedNode] = useState<{ id: string; group?: string } | null>(null);
  const [numPages, setNumPages] = useState<number>(1);
  const [pageNumber, setPageNumber] = useState<number>(1);
  const [pdfError, setPdfError] = useState<string | null>(null);
  const pdfContainerRef = useRef<HTMLDivElement | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["document", docId],
    enabled: !!docId,
    queryFn: async () => {
      const { data } = await api.get<DocumentAnalysis>(`/documents/${docId}`);
      return data;
    }
  });

  const { data: anomaliesData } = useQuery({
    queryKey: ["anomalies", docId],
    enabled: !!docId,
    queryFn: async () => {
      const { data } = await api.get<{ anomalies: AnomalyRecord[] }>(`/forensics/anomalies/${docId}`);
      return data.anomalies;
    }
  });

  const { data: txRecordsData } = useQuery({
    queryKey: ["transactions", docId],
    enabled: !!docId,
    queryFn: async () => {
      const { data } = await api.get<{ transactions: TransactionRecord[] }>(`/forensics/documents/${docId}/transactions`);
      return data.transactions;
    }
  });

  const anomalies = anomaliesData ?? [];
  const txRecords = txRecordsData ?? [];

  const correctionMutation = useMutation({
    mutationFn: async () => {
      if (!docId) return;
      await api.post(`/review/${docId}/correct`, {
        document_id: docId,
        field_name: correction.field_name,
        original_value: correction.original_value,
        corrected_value: correction.corrected_value,
        corrected_by: "web-reviewer"
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["document", docId] });
      confetti({ particleCount: 90, spread: 70, origin: { y: 0.7 } });
      setCorrection({
        field_name: "",
        original_value: "",
        corrected_value: ""
      });
    }
  });

  const approveMutation = useMutation({
    mutationFn: async () => {
      if (!docId) return;
      await api.post(`/review/${docId}/approve`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["reviewQueue"] });
    }
  });

  const reanalyzeMutation = useMutation({
    mutationFn: async () => {
      if (!docId) return;
      await api.post(`/review/${docId}/reanalyze`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["document", docId] });
    }
  });

  if (!docId) {
    return <Text>Missing document id.</Text>;
  }

  if (isLoading || !data) {
    return (
      <HStack spacing={3} color="whiteAlpha.700">
        <Spinner size="sm" />
        <Text fontSize="sm">Loading document...</Text>
      </HStack>
    );
  }

  const { classification, validation, quality_metrics, layout, knowledge_graph } = data;
  const extractedFields = data.extracted_fields ?? {};
  const isBankStatement = classification.type === "bank_statement";
  const isPdf = data.filename?.toLowerCase().endsWith(".pdf");
  const isExcel = data.filename?.toLowerCase().endsWith(".xlsx") || data.filename?.toLowerCase().endsWith(".xls") || data.filename?.toLowerCase().endsWith(".csv");

  const transactions = useMemo(() => {
    const raw = extractedFields.transactions;
    if (!Array.isArray(raw)) return [] as Array<Record<string, unknown>>;
    return raw
      .map((item, index) => {
        const amountRaw = (item as { amount?: unknown }).amount;
        const amount =
          typeof amountRaw === "number"
            ? amountRaw
            : typeof amountRaw === "string"
              ? Number.parseFloat(amountRaw.replace(/[^\d.-]/g, ""))
              : null;
        const balanceRaw = (item as { balance?: unknown }).balance;
        const balance =
          typeof balanceRaw === "number"
            ? balanceRaw
            : typeof balanceRaw === "string"
              ? Number.parseFloat(balanceRaw.replace(/[^\d.-]/g, ""))
              : null;
        return {
          index,
          date: String((item as { date?: unknown }).date ?? ""),
          description: String((item as { description?: unknown }).description ?? ""),
          amount,
          balance,
          currency: (item as { currency?: unknown }).currency ?? null
        };
      })
      .filter((txn) => txn.amount !== null || txn.description || txn.date);
  }, [extractedFields]);

  const amountThreshold = useMemo(() => {
    const values = transactions
      .map((txn) => Math.abs(txn.amount ?? 0))
      .filter((value) => Number.isFinite(value) && value > 0)
      .sort((a, b) => a - b);
    if (values.length < 8) return 10000;
    const idx = Math.floor(values.length * 0.9);
    return values[Math.min(idx, values.length - 1)] || 10000;
  }, [transactions]);

  const filteredTransactions = useMemo(() => {
    const minValue = minAmount ? Number.parseFloat(minAmount) : 0;
    return transactions.filter((txn) => {
      const matchesSearch = searchTerm
        ? `${txn.date} ${txn.description}`.toLowerCase().includes(searchTerm.toLowerCase())
        : true;
      const amountAbs = Math.abs(txn.amount ?? 0);
      const matchesAmount = Number.isFinite(amountAbs) ? amountAbs >= minValue : false;
      const isAnomaly = amountAbs >= amountThreshold || !txn.description || txn.balance === null;
      const matchesAnomaly = showAnomalies ? isAnomaly : true;
      return matchesSearch && matchesAmount && matchesAnomaly;
    });
  }, [transactions, searchTerm, minAmount, showAnomalies, amountThreshold]);

  const transactionSummary = useMemo(() => {
    const totalIn = transactions.reduce((acc, txn) => acc + (txn.amount && txn.amount > 0 ? txn.amount : 0), 0);
    const totalOut = transactions.reduce((acc, txn) => acc + (txn.amount && txn.amount < 0 ? Math.abs(txn.amount) : 0), 0);
    return {
      count: transactions.length,
      totalIn,
      totalOut,
      net: totalIn - totalOut
    };
  }, [transactions]);

  const benfordSeries = useMemo(() => {
    const digits = new Array(9).fill(0);
    transactions.forEach((txn) => {
      const value = Math.abs(txn.amount ?? 0);
      if (value < 1) return;
      const firstDigit = Number(String(Math.floor(value))[0]);
      if (firstDigit >= 1 && firstDigit <= 9) digits[firstDigit - 1] += 1;
    });
    const total = digits.reduce((a, b) => a + b, 0) || 1;
    return digits.map((count, idx) => {
      const digit = idx + 1;
      const expected = Math.log10(1 + 1 / digit);
      return {
        digit,
        observed: Number((count / total).toFixed(3)),
        expected: Number(expected.toFixed(3))
      };
    });
  }, [transactions]);

  const balanceSeries = useMemo(() => {
    if (transactions.length === 0) return [] as Array<Record<string, unknown>>;
    let running = typeof extractedFields.opening_balance === "number" ? extractedFields.opening_balance : null;
    return transactions.map((txn, idx) => {
      if (running === null && typeof txn.balance === "number") {
        running = txn.balance;
      } else if (running !== null && typeof txn.amount === "number") {
        running += txn.amount;
      }
      const expected = running;
      return {
        index: idx + 1,
        date: txn.date || `#${idx + 1}`,
        balance: typeof txn.balance === "number" ? txn.balance : null,
        expected
      };
    });
  }, [transactions, extractedFields.opening_balance]);

  const sankeyData = useMemo(() => {
    if (!transactions.length) {
      return {
        nodes: [],
        links: []
      } as {
        nodes: Array<{ name: string }>;
        links: Array<{ source: number; target: number; value: number }>;
      };
    }
    const categories = ["Income", "Expense", "Transfers", "Fees", "Card", "ATM", "Payments", "Interest", "Other"];
    const nodes = categories.map((name) => ({ name }));
    const links: Array<{ source: number; target: number; value: number }> = [];
    const categoryIndex = (category: string) => categories.indexOf(category);
    const classify = (desc: string, amount: number) => {
      const lower = desc.toLowerCase();
      if (lower.includes("fee") || lower.includes("charge")) return "Fees";
      if (lower.includes("card") || lower.includes("pos")) return "Card";
      if (lower.includes("atm") || lower.includes("cash")) return "ATM";
      if (lower.includes("transfer") || lower.includes("neft") || lower.includes("imps")) return "Transfers";
      if (lower.includes("interest")) return "Interest";
      if (lower.includes("payment") || lower.includes("bill") || lower.includes("upi")) return "Payments";
      if (amount >= 0) return "Income";
      return "Other";
    };
    const totals: Record<string, number> = {};
    transactions.forEach((txn) => {
      const amount = txn.amount ?? 0;
      const category = classify(txn.description, amount);
      const key = `${amount >= 0 ? "Income" : "Expense"}->${category}`;
      totals[key] = (totals[key] ?? 0) + Math.abs(amount);
    });
    Object.entries(totals).forEach(([key, value]) => {
      const [sourceName, targetName] = key.split("->");
      const source = categoryIndex(sourceName);
      const target = categoryIndex(targetName);
      if (source >= 0 && target >= 0 && value > 0) {
        links.push({ source, target, value: Number(value.toFixed(2)) });
      }
    });
    return { nodes, links };
  }, [transactions]);

  const graphData = useMemo(() => {
    if (!knowledge_graph) return { nodes: [], links: [] };
    return {
      nodes: knowledge_graph.nodes.map((n) => ({ id: n.id, group: n.type, label: n.type })),
      links: knowledge_graph.edges.map((e) => ({ source: e.source_id, target: e.target_id, label: e.type }))
    };
  }, [knowledge_graph]);

  const selectedTransaction = useMemo(() => {
    if (selectedTxnIndex === null) return null;
    return transactions.find((txn) => txn.index === selectedTxnIndex) ?? null;
  }, [transactions, selectedTxnIndex]);

  const evidenceAnchor = useMemo(() => {
    if (!selectedTransaction) return null;
    const amount = typeof selectedTransaction.amount === "number" ? selectedTransaction.amount.toFixed(2) : "-";
    return {
      date: selectedTransaction.date || "(no date)",
      description: selectedTransaction.description || "(missing memo)",
      amount,
      balance: typeof selectedTransaction.balance === "number" ? selectedTransaction.balance.toFixed(2) : "-"
    };
  }, [selectedTransaction]);

  const highlightText = useMemo(() => {
    if (!evidenceAnchor) return "";
    if (evidenceAnchor.amount && evidenceAnchor.amount !== "-") return evidenceAnchor.amount;
    return evidenceAnchor.description || "";
  }, [evidenceAnchor]);

  useEffect(() => {
    if (!isPdf || !highlightText) return;
    const timer = window.setTimeout(() => {
      const container = pdfContainerRef.current;
      if (!container) return;
      const match = container.querySelector("[data-evidence-match='true']");
      if (match) {
        (match as HTMLElement).scrollIntoView({ behavior: "smooth", block: "center" });
      }
    }, 350);
    return () => window.clearTimeout(timer);
  }, [isPdf, highlightText, pageNumber]);

  const renderText = (item: { str: string }) => {
    if (!highlightText) return item.str;
    const source = item.str;
    const token = highlightText.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    if (!token) return source;
    const parts = source.split(new RegExp(`(${token})`, "gi"));
    if (parts.length === 1) return source;
    return parts.map((part, index) =>
      part.toLowerCase() === highlightText.toLowerCase() ? (
        <mark key={`${part}-${index}`} data-evidence-match="true" style={{ backgroundColor: "#FF6B6B55" }}>
          {part}
        </mark>
      ) : (
        <span key={`${part}-${index}`}>{part}</span>
      )
    );
  };

  return (
    <VStack align="stretch" spacing={6}>
      <Box
        p={[4, 6]}
        borderRadius="24px"
        bg="linear-gradient(120deg, rgba(155,140,255,0.18), rgba(15,17,26,0.95))"
        border="1px solid"
        borderColor="whiteAlpha.100"
      >
        <Text fontSize="xs" color="aurora.violet" textTransform="uppercase" letterSpacing="0.2em">
          Inspector
        </Text>
        <Heading size="lg" mb={2}>
          {data.filename}
        </Heading>
        <HStack spacing={3} flexWrap="wrap">
          <Badge colorScheme="purple">{classification.type}</Badge>
          <Badge colorScheme={classification.confidence >= 0.8 ? "green" : "orange"}>
            {Math.round(classification.confidence * 100)}% confidence
          </Badge>
          <Badge colorScheme={data.status === "review" ? "orange" : "green"}>
            {data.status.toUpperCase()}
          </Badge>
          {anomalies && anomalies.length > 0 && (
            <Badge colorScheme="red" variant="subtle">
              {anomalies.length} anomalies
            </Badge>
          )}
          {txRecords && txRecords.length > 0 && (
            <Badge colorScheme="blue" variant="subtle">
              {txRecords.length} transactions
            </Badge>
          )}
        </HStack>
        <Text fontSize="sm" color="whiteAlpha.700" mt={3}>
          Cross-validate extracted fields, audit anomalies, and approve or correct
          the structured output.
        </Text>
      </Box>

      <SimpleGrid columns={[1, null, 2]} spacing={6}>
        <Box>
          <Box
            borderRadius="24px"
            border="1px solid"
            borderColor="whiteAlpha.100"
            overflow="hidden"
            minH="520px"
            bg="obsidian.900"
            boxShadow="soft"
          >
            {isPdf ? (
              <VStack align="stretch" spacing={2} p={3} height="100%">
                <HStack justify="space-between">
                  <Text fontSize="xs" color="whiteAlpha.600">
                    Evidence Bridge · Highlight: {highlightText || "Select a row"}
                  </Text>
                  <HStack spacing={1}>
                    <IconButton
                      aria-label="Previous page"
                      icon={<FiChevronLeft />}
                      size="xs"
                      variant="ghost"
                      onClick={() => setPageNumber((p) => Math.max(1, p - 1))}
                      isDisabled={pageNumber <= 1}
                    />
                    <Text fontSize="xs" color="whiteAlpha.600">
                      {pageNumber} / {numPages}
                    </Text>
                    <IconButton
                      aria-label="Next page"
                      icon={<FiChevronRight />}
                      size="xs"
                      variant="ghost"
                      onClick={() => setPageNumber((p) => Math.min(numPages, p + 1))}
                      isDisabled={pageNumber >= numPages}
                    />
                  </HStack>
                </HStack>
                <Box ref={pdfContainerRef} overflowY="auto" flex="1">
                  <Document
                    file={`/api/documents/${encodeURIComponent(data.document_id)}/file`}
                    onLoadSuccess={(info) => {
                      setNumPages(info.numPages || 1);
                      setPageNumber(1);
                      setPdfError(null);
                    }}
                    onLoadError={(err) => setPdfError(err?.message ?? "Failed to load PDF")}
                    onSourceError={(err) => setPdfError(err?.message ?? "Failed to load PDF")}
                    loading={
                      <HStack spacing={2} color="whiteAlpha.600" p={3}>
                        <Spinner size="sm" />
                        <Text fontSize="sm">Loading evidence...</Text>
                      </HStack>
                    }
                  >
                    {pdfError ? (
                      <VStack align="stretch" spacing={2} p={3}>
                        <Text fontSize="sm" color="red.300">
                          {pdfError}
                        </Text>
                        <Button
                          size="xs"
                          variant="outline"
                          onClick={() => window.open(`/api/documents/${encodeURIComponent(data.document_id)}/file`, "_blank")}
                        >
                          Open PDF in new tab
                        </Button>
                      </VStack>
                    ) : (
                      <Page
                        pageNumber={pageNumber}
                        width={520}
                        renderTextLayer
                        customTextRenderer={renderText}
                      />
                    )}
                  </Document>
                </Box>
              </VStack>
            ) : isExcel ? (
              <VStack spacing={6} justify="center" height="100%" p={6}>
                <Box
                  border="2px dashed"
                  borderColor="green.700"
                  borderRadius="xl"
                  p={8}
                  width="100%"
                  textAlign="center"
                >
                  <VStack spacing={4}>
                    <Icon as={FiDatabase} w={14} h={14} color="green.400" />
                    <Badge colorScheme="green" fontSize="sm" px={3} py={1} borderRadius="full">
                      DIGITAL LEDGER
                    </Badge>
                    <Text color="gray.400" fontSize="md">
                      Structured Excel data — no image preview needed
                    </Text>
                    <Divider borderColor="whiteAlpha.200" />
                    <SimpleGrid columns={2} spacing={4} width="100%">
                      <Stat textAlign="center">
                        <StatLabel color="whiteAlpha.600" fontSize="xs">Opening</StatLabel>
                        <StatNumber fontSize="md" color="green.300">
                          {typeof extractedFields.opening_balance === "number"
                            ? extractedFields.opening_balance.toLocaleString(undefined, { minimumFractionDigits: 2 })
                            : "-"}
                        </StatNumber>
                      </Stat>
                      <Stat textAlign="center">
                        <StatLabel color="whiteAlpha.600" fontSize="xs">Closing</StatLabel>
                        <StatNumber fontSize="md" color="blue.300">
                          {typeof extractedFields.closing_balance === "number"
                            ? extractedFields.closing_balance.toLocaleString(undefined, { minimumFractionDigits: 2 })
                            : "-"}
                        </StatNumber>
                      </Stat>
                    </SimpleGrid>
                    <Text fontSize="sm" color="whiteAlpha.500">
                      {transactionSummary.count} transactions parsed · Quality: {typeof quality_metrics?.score === "number" ? `${Math.round(quality_metrics.score * 100)}%` : "Digital (100%)"}
                    </Text>
                    <Button
                      leftIcon={<FiDownload />}
                      colorScheme="green"
                      variant="outline"
                      size="sm"
                      onClick={() => window.open(`/api/documents/${encodeURIComponent(data.document_id)}/file`, "_blank")}
                    >
                      Download Original File
                    </Button>
                    <Text fontSize="xs" color="whiteAlpha.400">
                      Review extracted data in the intelligence panel →
                    </Text>
                  </VStack>
                </Box>
              </VStack>
            ) : (
              <VStack align="stretch" spacing={3} p={6} height="100%" justify="center">
                <Icon as={FiFileText} w={10} h={10} color="purple.400" />
                <Heading size="sm">Evidence preview unavailable</Heading>
                <Text fontSize="sm" color="whiteAlpha.700">
                  This file format does not support in-browser preview.
                  Use the transaction intelligence panel to audit the extracted rows.
                </Text>
                <Button
                  leftIcon={<FiDownload />}
                  size="sm"
                  colorScheme="purple"
                  variant="outline"
                  alignSelf="flex-start"
                  onClick={() => window.open(`/api/documents/${encodeURIComponent(data.document_id)}/file`, "_blank")}
                >
                  Open original file
                </Button>
              </VStack>
            )}
          </Box>
        </Box>

        <VStack align="stretch" spacing={5}>
          <Box
            p={5}
            borderRadius="24px"
            bg="whiteAlpha.50"
            border="1px solid"
            borderColor="whiteAlpha.100"
            boxShadow="soft"
          >
            <HStack justify="space-between" mb={4}>
              <Heading size="sm">Validation status</Heading>
              <Badge colorScheme={validation.valid ? "green" : "orange"}>
                {validation.valid ? "PASS" : "REVIEW"}
              </Badge>
            </HStack>
            <Text fontSize="sm" color="whiteAlpha.700" mb={2}>
              {validation.errors.length} errors · {validation.warnings.length} warnings
            </Text>
            {quality_metrics?.warnings && (
              <Box mb={3}>
                <Text fontSize="xs" color="whiteAlpha.600" mb={1}>
                  Quality alerts
                </Text>
                <VStack align="stretch" spacing={1}>
                  {(quality_metrics.warnings as string[]).map((w, idx) => (
                    <Text key={`q-${idx}`} fontSize="xs" color="orange.300">
                      • {w}
                    </Text>
                  ))}
                </VStack>
              </Box>
            )}
            <VStack align="stretch" spacing={2}>
              {validation.errors.map((err, idx) => (
                <Text key={`e-${idx}`} fontSize="xs" color="red.300">
                  • {(err as { message?: string }).message ?? JSON.stringify(err)}
                </Text>
              ))}
              {validation.warnings.map((w, idx) => (
                <Text key={`w-${idx}`} fontSize="xs" color="yellow.300">
                  • {(w as { message?: string }).message ?? JSON.stringify(w)}
                </Text>
              ))}
            </VStack>
            <Button
              mt={4}
              size="sm"
              colorScheme="green"
              onClick={() => approveMutation.mutate()}
              isLoading={approveMutation.isPending}
            >
              Approve extraction
            </Button>
            <Button
              mt={2}
              size="xs"
              variant="outline"
              onClick={() => reanalyzeMutation.mutate()}
              isLoading={reanalyzeMutation.isPending}
            >
              Re-run AI analysis
            </Button>
          </Box>

          <Box
            p={5}
            borderRadius="24px"
            bg="whiteAlpha.50"
            border="1px solid"
            borderColor="whiteAlpha.100"
            boxShadow="soft"
          >
            <Heading size="sm" mb={3}>
              Layout signals
            </Heading>
            <HStack spacing={2} flexWrap="wrap">
              {layout?.tables && <Badge colorScheme="purple">Tables</Badge>}
              {layout?.handwriting && <Badge colorScheme="orange">Handwriting</Badge>}
              {layout?.stamps && <Badge colorScheme="pink">Stamps</Badge>}
              {layout?.signatures && <Badge colorScheme="blue">Signatures</Badge>}
              {layout?.headers && <Badge colorScheme="teal">Headers</Badge>}
              {!layout && <Text fontSize="xs">No layout metadata.</Text>}
            </HStack>
            <Text fontSize="xs" color="whiteAlpha.600" mt={2}>
              Quality score: {typeof quality_metrics?.score === "number" ? `${Math.round(quality_metrics.score * 100)}%` : "-"}
            </Text>
          </Box>

          {isBankStatement && (
            <Box
              p={5}
              borderRadius="24px"
              bg="whiteAlpha.50"
              border="1px solid"
              borderColor="whiteAlpha.100"
              boxShadow="soft"
            >
              <HStack justify="space-between" mb={4}>
                <Heading size="sm">Statement intelligence</Heading>
                <Badge colorScheme="purple">Excel-first</Badge>
              </HStack>

              <SimpleGrid columns={[1, 2]} spacing={3} mb={4}>
                <Stat p={3} borderRadius="16px" bg="whiteAlpha.100">
                  <StatLabel>Transactions</StatLabel>
                  <StatNumber>{transactionSummary.count}</StatNumber>
                  <StatHelpText>rows parsed</StatHelpText>
                </Stat>
                <Stat p={3} borderRadius="16px" bg="whiteAlpha.100">
                  <StatLabel>Net flow</StatLabel>
                  <StatNumber>{transactionSummary.net.toFixed(2)}</StatNumber>
                  <StatHelpText>{transactionSummary.totalIn.toFixed(2)} in / {transactionSummary.totalOut.toFixed(2)} out</StatHelpText>
                </Stat>
              </SimpleGrid>

              <Tabs variant="soft-rounded" colorScheme="purple">
                <TabList flexWrap="wrap" gap={2}>
                  <Tab>Transactions</Tab>
                  <Tab>Recon</Tab>
                  <Tab>Benford</Tab>
                  <Tab>Flow</Tab>
                  <Tab>Balance</Tab>
                </TabList>
                <TabPanels mt={3}>
                  <TabPanel px={0}>
                    <HStack spacing={3} mb={3} flexWrap="wrap">
                      <Input
                        size="sm"
                        placeholder="Search description"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                      />
                      <Input
                        size="sm"
                        placeholder="Min amount"
                        value={minAmount}
                        onChange={(e) => setMinAmount(e.target.value)}
                        maxW="160px"
                      />
                      <FormControl display="flex" alignItems="center" gap={2} maxW="180px">
                        <FormLabel fontSize="xs" mb="0">
                          Anomalies
                        </FormLabel>
                        <Switch size="sm" isChecked={showAnomalies} onChange={(e) => setShowAnomalies(e.target.checked)} />
                      </FormControl>
                    </HStack>
                    <Box maxH="260px" overflowY="auto">
                      <Table size="sm">
                        <Thead>
                          <Tr>
                            <Th color="whiteAlpha.600">Date</Th>
                            <Th color="whiteAlpha.600">Description</Th>
                            <Th color="whiteAlpha.600" isNumeric>
                              Amount
                            </Th>
                            <Th color="whiteAlpha.600" isNumeric>
                              Balance
                            </Th>
                          </Tr>
                        </Thead>
                        <Tbody>
                          {filteredTransactions.map((txn) => {
                            const amountAbs = Math.abs(txn.amount ?? 0);
                            const isAnomaly = amountAbs >= amountThreshold || !txn.description || txn.balance === null;
                            return (
                              <Tr
                                key={`txn-${txn.index}`}
                                bg={isAnomaly ? "red.900" : undefined}
                                cursor="pointer"
                                onClick={() => setSelectedTxnIndex(txn.index)}
                              >
                                <Td>{txn.date || "-"}</Td>
                                <Td>{txn.description || "(missing memo)"}</Td>
                                <Td isNumeric color={txn.amount && txn.amount < 0 ? "orange.300" : "green.300"}>
                                  {typeof txn.amount === "number" ? txn.amount.toFixed(2) : "-"}
                                </Td>
                                <Td isNumeric>{typeof txn.balance === "number" ? txn.balance.toFixed(2) : "-"}</Td>
                              </Tr>
                            );
                          })}
                          {filteredTransactions.length === 0 && (
                            <Tr>
                              <Td colSpan={4}>
                                <Text fontSize="sm" color="whiteAlpha.600">
                                  No transactions matched your filters.
                                </Text>
                              </Td>
                            </Tr>
                          )}
                        </Tbody>
                      </Table>
                    </Box>
                  </TabPanel>
                  <TabPanel px={0}>
                    <VStack align="stretch" spacing={3}>
                      <Text fontSize="sm" color="whiteAlpha.700">
                        Reconciliation bridge ties each Excel row to evidence. Select a transaction to focus the audit trail.
                      </Text>
                      <Divider borderColor="whiteAlpha.200" />
                      {selectedTxnIndex === null ? (
                        <Text fontSize="sm" color="whiteAlpha.600">
                          Select a transaction from the table to view its reconciliation summary.
                        </Text>
                      ) : (
                        <Box p={4} borderRadius="16px" bg="whiteAlpha.100">
                          {evidenceAnchor ? (
                            <VStack align="stretch" spacing={2}>
                              <Text fontSize="sm" fontWeight="semibold">
                                {evidenceAnchor.date} · {evidenceAnchor.description}
                              </Text>
                              <Text fontSize="xs" color="whiteAlpha.600">
                                Amount: {evidenceAnchor.amount}
                              </Text>
                              <Text fontSize="xs" color="whiteAlpha.600">
                                Balance: {evidenceAnchor.balance}
                              </Text>
                              <HStack spacing={2}>
                                <Button size="xs" colorScheme="purple" alignSelf="flex-start">
                                  Tag as verified
                                </Button>
                                <Button
                                  size="xs"
                                  variant="outline"
                                  onClick={() => window.open(`/api/documents/${encodeURIComponent(data.document_id)}/file`, "_blank")}
                                >
                                  Open evidence
                                </Button>
                              </HStack>
                            </VStack>
                          ) : null}
                        </Box>
                      )}
                    </VStack>
                  </TabPanel>
                  <TabPanel px={0}>
                    <Box height="220px">
                      <ResponsiveContainer width="100%" height="100%">
                        <BarChart data={benfordSeries} margin={{ left: 8, right: 8 }}>
                          <XAxis dataKey="digit" tick={{ fill: "#C7C7D1", fontSize: 10 }} />
                          <YAxis tick={{ fill: "#C7C7D1", fontSize: 10 }} />
                          <RechartsTooltip />
                          <Legend />
                          <Bar dataKey="observed" fill="#9B8CFF" radius={[4, 4, 0, 0]} />
                          <Bar dataKey="expected" fill="#4FD1C5" radius={[4, 4, 0, 0]} />
                        </BarChart>
                      </ResponsiveContainer>
                    </Box>
                  </TabPanel>
                  <TabPanel px={0}>
                    <Box height="240px">
                      <ResponsiveContainer width="100%" height="100%">
                        <Sankey
                          data={sankeyData}
                          nodePadding={20}
                          nodeWidth={12}
                          link={{ stroke: "#9B8CFF" }}
                        >
                          <RechartsTooltip />
                        </Sankey>
                      </ResponsiveContainer>
                    </Box>
                  </TabPanel>
                  <TabPanel px={0}>
                    <Box height="240px">
                      <ResponsiveContainer width="100%" height="100%">
                        <LineChart data={balanceSeries} margin={{ left: 8, right: 8 }}>
                          <XAxis dataKey="date" tick={{ fill: "#C7C7D1", fontSize: 9 }} />
                          <YAxis tick={{ fill: "#C7C7D1", fontSize: 10 }} />
                          <RechartsTooltip />
                          <Legend />
                          <Line type="monotone" dataKey="balance" stroke="#FF6B6B" dot={false} />
                          <Line type="monotone" dataKey="expected" stroke="#9B8CFF" strokeDasharray="4 4" dot={false} />
                        </LineChart>
                      </ResponsiveContainer>
                    </Box>
                  </TabPanel>
                </TabPanels>
              </Tabs>
            </Box>
          )}

          <Box
            p={5}
            borderRadius="24px"
            bg="whiteAlpha.50"
            border="1px solid"
            borderColor="whiteAlpha.100"
            boxShadow="soft"
          >
            <Heading size="sm" mb={3}>
              Extracted fields
            </Heading>
            {(() => {
              const fieldEntries = Object.entries(extractedFields).filter(
                ([key]) => key !== "transactions"
              );
              return (
                <Table size="sm">
                  <Thead>
                    <Tr>
                      <Th color="whiteAlpha.600">Field</Th>
                      <Th color="whiteAlpha.600">Value</Th>
                    </Tr>
                  </Thead>
                  <Tbody>
                    {fieldEntries.map(([key, value]) => (
                      <Tr key={key}>
                        <Td>{key}</Td>
                        <Td>{String(value)}</Td>
                      </Tr>
                    ))}
                    {fieldEntries.length === 0 && (
                      <Tr>
                        <Td colSpan={2}>
                          <Text fontSize="sm" color="whiteAlpha.600">
                            No structured fields available.
                          </Text>
                        </Td>
                      </Tr>
                    )}
                  </Tbody>
                </Table>
              );
            })()}
          </Box>

          <Box
            p={5}
            borderRadius="24px"
            bg="whiteAlpha.50"
            border="1px solid"
            borderColor="whiteAlpha.100"
            boxShadow="soft"
          >
            <Heading size="sm" mb={3}>
              Submit correction
            </Heading>
            <VStack align="stretch" spacing={2}>
              <Input
                size="sm"
                placeholder="Field name"
                value={correction.field_name}
                onChange={(e) =>
                  setCorrection((c) => ({ ...c, field_name: e.target.value }))
                }
              />
              <Input
                size="sm"
                placeholder="Original value"
                value={correction.original_value}
                onChange={(e) =>
                  setCorrection((c) => ({ ...c, original_value: e.target.value }))
                }
              />
              <Input
                size="sm"
                placeholder="Corrected value"
                value={correction.corrected_value}
                onChange={(e) =>
                  setCorrection((c) => ({ ...c, corrected_value: e.target.value }))
                }
              />
              <Button
                size="sm"
                colorScheme="purple"
                alignSelf="flex-start"
                isLoading={correctionMutation.isPending}
                onClick={() => correctionMutation.mutate()}
                isDisabled={!correction.field_name || !correction.corrected_value}
              >
                Submit correction
              </Button>
            </VStack>
          </Box>

          {/* Forensic Anomaly Panel */}
          {anomalies && anomalies.length > 0 && (
            <Box
              p={5}
              borderRadius="24px"
              bg="rgba(255,107,107,0.06)"
              border="1px solid"
              borderColor="rgba(255,107,107,0.25)"
              boxShadow="soft"
            >
              <HStack justify="space-between" mb={3}>
                <Heading size="sm">Forensic anomalies</Heading>
                <Badge colorScheme="red" variant="subtle">
                  {anomalies.length} detected
                </Badge>
              </HStack>
              <VStack align="stretch" spacing={2} maxH="320px" overflowY="auto">
                {anomalies.map((a) => (
                  <Box
                    key={a.id}
                    p={3}
                    borderRadius="12px"
                    bg={
                      a.severity === "critical"
                        ? "rgba(255,107,107,0.12)"
                        : a.severity === "warning"
                        ? "rgba(255,184,108,0.10)"
                        : "whiteAlpha.100"
                    }
                    border="1px solid"
                    borderColor={
                      a.severity === "critical"
                        ? "rgba(255,107,107,0.3)"
                        : a.severity === "warning"
                        ? "rgba(255,184,108,0.25)"
                        : "whiteAlpha.200"
                    }
                  >
                    <HStack justify="space-between" mb={1}>
                      <Badge
                        colorScheme={
                          a.severity === "critical"
                            ? "red"
                            : a.severity === "warning"
                            ? "orange"
                            : "purple"
                        }
                        variant="subtle"
                        fontSize="2xs"
                      >
                        {a.severity.toUpperCase()}
                      </Badge>
                      <Badge colorScheme="purple" variant="outline" fontSize="2xs">
                        {a.type.replace(/_/g, " ")}
                      </Badge>
                    </HStack>
                    <Text fontSize="xs" color="whiteAlpha.800">
                      {a.description}
                    </Text>
                    {a.row_index !== null && (
                      <Text fontSize="2xs" color="whiteAlpha.500" mt={1}>
                        Row {a.row_index}
                      </Text>
                    )}
                  </Box>
                ))}
              </VStack>
            </Box>
          )}

          {/* Transaction Records from Backend */}
          {txRecords && txRecords.length > 0 && (
            <Box
              p={5}
              borderRadius="24px"
              bg="whiteAlpha.50"
              border="1px solid"
              borderColor="whiteAlpha.100"
              boxShadow="soft"
            >
              <HStack justify="space-between" mb={3}>
                <Heading size="sm">Normalized transactions</Heading>
                <HStack spacing={2}>
                  <Badge colorScheme="purple" variant="subtle">
                    {txRecords.length} rows
                  </Badge>
                  <Badge colorScheme="red" variant="subtle">
                    {txRecords.filter(t => t.is_anomaly).length} flagged
                  </Badge>
                </HStack>
              </HStack>
              <Box maxH="300px" overflowY="auto">
                <Table size="sm">
                  <Thead>
                    <Tr>
                      <Th color="whiteAlpha.600">#</Th>
                      <Th color="whiteAlpha.600">Date</Th>
                      <Th color="whiteAlpha.600">Description</Th>
                      <Th color="whiteAlpha.600">Category</Th>
                      <Th color="whiteAlpha.600" isNumeric>Amount</Th>
                      <Th color="whiteAlpha.600" isNumeric>Balance</Th>
                      <Th color="whiteAlpha.600">Flag</Th>
                    </Tr>
                  </Thead>
                  <Tbody>
                    {txRecords.slice(0, 100).map((tx) => (
                      <Tr
                        key={tx.id}
                        bg={tx.is_anomaly ? "red.900" : undefined}
                        _hover={{ bg: "whiteAlpha.100" }}
                      >
                        <Td fontSize="xs">{tx.row_index}</Td>
                        <Td fontSize="xs">{tx.date ?? "-"}</Td>
                        <Td fontSize="xs" maxW="180px" isTruncated>
                          {tx.merchant_normalized || tx.description || "-"}
                        </Td>
                        <Td>
                          {tx.category && (
                            <Badge colorScheme="purple" variant="subtle" fontSize="2xs">
                              {tx.category}
                            </Badge>
                          )}
                        </Td>
                        <Td isNumeric fontSize="xs" color={tx.amount && tx.amount < 0 ? "orange.300" : "green.300"}>
                          {tx.amount != null ? tx.amount.toLocaleString(undefined, { minimumFractionDigits: 2 }) : "-"}
                        </Td>
                        <Td isNumeric fontSize="xs">
                          {tx.balance_after != null ? tx.balance_after.toLocaleString(undefined, { minimumFractionDigits: 2 }) : "-"}
                        </Td>
                        <Td>
                          {tx.is_anomaly && (
                            <Badge colorScheme="red" variant="subtle" fontSize="2xs">
                              {tx.anomaly_tags ?? "FLAGGED"}
                            </Badge>
                          )}
                        </Td>
                      </Tr>
                    ))}
                  </Tbody>
                </Table>
              </Box>
              {txRecords.length > 100 && (
                <Text fontSize="xs" color="whiteAlpha.500" mt={2}>
                  Showing first 100 of {txRecords.length} transactions.
                </Text>
              )}
            </Box>
          )}

          <Box
            p={5}
            borderRadius="24px"
            bg="whiteAlpha.50"
            border="1px solid"
            borderColor="whiteAlpha.100"
            boxShadow="soft"
          >
            <Heading size="sm" mb={3}>
              Knowledge graph
            </Heading>
            {knowledge_graph ? (
              <Box height="320px">
                <ForceGraph3D
                  graphData={graphData}
                  nodeLabel={(node) => `${node.group}: ${node.id}`}
                  linkLabel={(link) => link.label}
                  nodeAutoColorBy="group"
                  backgroundColor="#0A0A0F"
                />
              </Box>
            ) : (
              <Text fontSize="sm" color="whiteAlpha.600">
                No knowledge graph data available yet.
              </Text>
            )}
          </Box>
        </VStack>
      </SimpleGrid>
    </VStack>
  );
}

