import {
  Badge,
  Box,
  Button,
  CircularProgress,
  CircularProgressLabel,
  Drawer,
  DrawerBody,
  DrawerCloseButton,
  DrawerContent,
  DrawerHeader,
  DrawerOverlay,
  Heading,
  HStack,
  Input,
  Progress,
  SimpleGrid,
  Spinner,
  Stat,
  StatHelpText,
  StatLabel,
  StatNumber,
  Table,
  Tbody,
  Td,
  Text,
  Th,
  Thead,
  Tooltip,
  Tr,
  VStack,
  useToast
} from "@chakra-ui/react";
import { useMutation } from "@tanstack/react-query";
import { useRef, useState } from "react";
import { FiAlertTriangle, FiClock, FiShield, FiUploadCloud, FiZap } from "react-icons/fi";

import { api } from "../api/client";
import type { IngestionSummary } from "../api/types";

export default function IngestionPage() {
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const toast = useToast();
  const [documents, setDocuments] = useState<IngestionSummary[]>([]);
  const [selectedDocId, setSelectedDocId] = useState<string | null>(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [isDragging, setIsDragging] = useState(false);
  const [lastBatchId, setLastBatchId] = useState<string | null>(null);
  const [uploadStartTime, setUploadStartTime] = useState<number | null>(null);
  const [uploadElapsed, setUploadElapsed] = useState<number | null>(null);

  const totalAnomalies = documents.reduce((acc, d) => acc + (d.anomalies_count ?? 0), 0);
  const avgProcessing = documents.filter(d => d.processing_time_ms).length
    ? Math.round(documents.reduce((acc, d) => acc + (d.processing_time_ms ?? 0), 0) / documents.filter(d => d.processing_time_ms).length)
    : null;
  const reviewCount = documents.filter(d => d.status === "review").length;
  const criticalCount = documents.filter(d => (d.anomalies_count ?? 0) > 3).length;

  const ingestMutation = useMutation({
    mutationFn: async (files: FileList) => {
      setUploadStartTime(Date.now());
      const formData = new FormData();
      Array.from(files).forEach((file) => {
        formData.append("files", file);
      });
      const { data } = await api.post<{ documents: IngestionSummary[]; batch_id?: string }>(
        "/ingestion/documents",
        formData,
        { headers: { "Content-Type": "multipart/form-data" } }
      );
      return data;
    },
    onSuccess: (response) => {
      const docs = response.documents;
      setDocuments((prev) => [...docs, ...prev]);
      if (response.batch_id) setLastBatchId(response.batch_id);
      if (uploadStartTime) setUploadElapsed(Date.now() - uploadStartTime);
      if (docs[0]?.document_id) {
        setSelectedDocId(docs[0].document_id ?? null);
      }
      const totalAnoms = docs.reduce((acc, d) => acc + (d.anomalies_count ?? 0), 0);
      toast({
        title: "Ingestion complete",
        description: `${docs.length} document(s) processed. ${totalAnoms} anomalies detected.`,
        status: totalAnoms > 0 ? "warning" : "success",
        duration: 4000,
        isClosable: true
      });
    },
    onError: (err: unknown) => {
      console.error(err);
      setUploadElapsed(null);
      toast({
        title: "Ingestion failed",
        description: "Unable to upload documents. Check backend logs.",
        status: "error",
        duration: 4000,
        isClosable: true
      });
    }
  });

  const onSelectFiles = () => fileInputRef.current?.click();

  const onFilesChanged = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return;
    ingestMutation.mutate(e.target.files);
    e.target.value = "";
  };

  const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    setIsDragging(false);
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      ingestMutation.mutate(e.dataTransfer.files);
      e.dataTransfer.clearData();
    }
  };

  return (
    <VStack align="stretch" spacing={8}>
      <Box
        p={[4, 6]}
        borderRadius="24px"
        bg="linear-gradient(120deg, rgba(65,234,212,0.16), rgba(15,17,26,0.95))"
        border="1px solid"
        borderColor="whiteAlpha.100"
      >
        <Text fontSize="xs" color="aurora.violet" textTransform="uppercase" letterSpacing="0.2em">
          Ingestion Bay
        </Text>
        <Heading size="lg">Drag. Drop. Diagnose.</Heading>
        <Text fontSize="sm" color="whiteAlpha.700" maxW="640px">
          Upload bank statements, invoices, payslips, and contracts. Aegis
          classifies, extracts, and validates everything against your financial memory.
        </Text>
        <HStack spacing={4} mt={4} flexWrap="wrap">
          <Badge colorScheme="green" variant="subtle">
            OCR + Layout
          </Badge>
          <Badge colorScheme="purple" variant="subtle">
            Schema Extract
          </Badge>
          <Badge colorScheme="orange" variant="subtle">
            Validation
          </Badge>
        </HStack>
      </Box>

      <SimpleGrid columns={[1, null, 2]} spacing={6}>
        <Box
          p={8}
          borderRadius="24px"
          bg="whiteAlpha.50"
          border="1px solid"
          borderColor="whiteAlpha.100"
          backdropFilter="blur(12px)"
          boxShadow="soft"
          onDragOver={(e) => {
            e.preventDefault();
            setIsDragging(true);
          }}
          onDragLeave={() => setIsDragging(false)}
          onDrop={handleDrop}
        >
          <VStack spacing={4} align="start">
            <HStack spacing={3}>
              <Box
                p={3}
                borderRadius="16px"
                bg="whiteAlpha.100"
                color="aurora.coral"
              >
                <FiUploadCloud />
              </Box>
              <Box>
                <Text fontWeight="semibold">Drop files for instant analysis</Text>
                <Text fontSize="xs" color="whiteAlpha.600">
                  Supported: PDF, PNG, JPG, JPEG, WEBP, TIFF, XLSX
                </Text>
              </Box>
            </HStack>

            <Box
              w="full"
              borderRadius="20px"
              border="1px dashed"
              borderColor={isDragging ? "aurora.violet" : "whiteAlpha.200"}
              bg={isDragging ? "whiteAlpha.100" : "whiteAlpha.50"}
              p={6}
              textAlign="center"
              color="whiteAlpha.700"
            >
              <Text fontSize="sm" fontWeight="medium">
                {isDragging ? "Release to ingest" : "Drag documents here"}
              </Text>
              <Text fontSize="xs">We preserve your layout + table structure.</Text>
            </Box>

            <Input
              ref={fileInputRef}
              type="file"
              multiple
              accept=".pdf,.png,.jpg,.jpeg,.webp,.tif,.tiff,.xlsx"
              display="none"
              onChange={onFilesChanged}
            />

            <Button
              onClick={onSelectFiles}
              colorScheme="purple"
              bg="aurora.violet"
              _hover={{ bg: "#8a7bff" }}
              isLoading={ingestMutation.isPending}
            >
              {ingestMutation.isPending ? "Analyzing" : "Select documents"}
            </Button>
            <Text fontSize="xs" color="whiteAlpha.600">
              Files are stored securely and only used for extraction and validation.
            </Text>
          </VStack>
        </Box>

        <Box
          p={8}
          borderRadius="24px"
          bg="linear-gradient(135deg, rgba(255,107,107,0.14), rgba(155,140,255,0.12))"
          border="1px solid"
          borderColor="whiteAlpha.100"
          boxShadow="soft"
        >
          <VStack align="start" spacing={4}>
            <Text fontSize="sm" color="whiteAlpha.700">
              Live ingestion status
            </Text>
            <Heading size="md">Autonomous audit pipeline</Heading>
            <Text fontSize="sm" color="whiteAlpha.700">
              The pipeline runs classification, schema-aware extraction, and
              validation in a single pass using Backboard intelligence.
            </Text>
            <SimpleGrid columns={2} spacing={3} w="full">
              <Stat p={3} borderRadius="16px" bg="whiteAlpha.100">
                <StatLabel>Ingested</StatLabel>
                <StatNumber>{documents.length}</StatNumber>
                <StatHelpText>this session</StatHelpText>
              </Stat>
              <Stat p={3} borderRadius="16px" bg="whiteAlpha.100">
                <StatLabel>
                  <HStack spacing={1}><FiAlertTriangle size={12} /><Text>Anomalies</Text></HStack>
                </StatLabel>
                <StatNumber color={totalAnomalies > 0 ? "orange.300" : "green.300"}>{totalAnomalies}</StatNumber>
                <StatHelpText>forensic flags</StatHelpText>
              </Stat>
              <Stat p={3} borderRadius="16px" bg="whiteAlpha.100">
                <StatLabel>
                  <HStack spacing={1}><FiShield size={12} /><Text>Review</Text></HStack>
                </StatLabel>
                <StatNumber color={reviewCount > 0 ? "orange.300" : "green.300"}>{reviewCount}</StatNumber>
                <StatHelpText>{criticalCount} critical</StatHelpText>
              </Stat>
              <Stat p={3} borderRadius="16px" bg="whiteAlpha.100">
                <StatLabel>
                  <HStack spacing={1}><FiClock size={12} /><Text>Avg time</Text></HStack>
                </StatLabel>
                <StatNumber>{avgProcessing ? `${(avgProcessing / 1000).toFixed(1)}s` : "-"}</StatNumber>
                <StatHelpText>per document</StatHelpText>
              </Stat>
            </SimpleGrid>
            {lastBatchId && (
              <HStack spacing={2} w="full">
                <Badge colorScheme="purple" variant="subtle" fontSize="2xs">
                  <HStack spacing={1}><FiZap size={10} /><Text>Batch {lastBatchId.slice(0, 8)}</Text></HStack>
                </Badge>
                {uploadElapsed && (
                  <Badge colorScheme="green" variant="subtle" fontSize="2xs">
                    {(uploadElapsed / 1000).toFixed(1)}s total
                  </Badge>
                )}
              </HStack>
            )}
          </VStack>
        </Box>
      </SimpleGrid>

      <HStack justify="space-between">
        <Heading size="sm">Recent uploads</Heading>
        {ingestMutation.isPending && (
          <HStack spacing={3} color="whiteAlpha.700" flex="1" ml={4}>
            <Progress size="xs" isIndeterminate colorScheme="purple" flex="1" borderRadius="full" />
            <Text fontSize="xs" whiteSpace="nowrap">Processing pipeline...</Text>
          </HStack>
        )}
      </HStack>

      <Box
        borderRadius="20px"
        bg="blackAlpha.700"
        border="1px solid"
        borderColor="whiteAlpha.200"
        p={4}
        boxShadow="soft"
      >
        <HStack justify="space-between" mb={2}>
          <Text fontSize="xs" color="whiteAlpha.600" textTransform="uppercase" letterSpacing="0.2em">
            Pipeline Console
          </Text>
          <HStack spacing={2}>
            <Text fontSize="xs" color="whiteAlpha.500">
              {selectedDocId ?? "No selection"}
            </Text>
            <Button
              size="xs"
              variant="ghost"
              onClick={() => setIsDrawerOpen(true)}
              isDisabled={!selectedDocId}
            >
              View full backend trace
            </Button>
          </HStack>
        </HStack>
        {(() => {
          const selected = documents.find((doc) => doc.document_id === selectedDocId) ?? documents[0];
          const logLines = selected?.debug_log?.length
            ? selected.debug_log
            : ["Upload a document to see the ingestion trace."];
          return (
            <Box
              as="pre"
              fontSize="xs"
              color="green.200"
              whiteSpace="pre-wrap"
              fontFamily="mono"
              maxH="220px"
              overflowY="auto"
            >
              {logLines.map((line, idx) => `> ${line}${idx < logLines.length - 1 ? "\n" : ""}`)}
            </Box>
          );
        })()}
      </Box>

      <Box
        borderRadius="24px"
        bg="whiteAlpha.50"
        border="1px solid"
        borderColor="whiteAlpha.100"
        overflowX="auto"
      >
        <Table size="sm">
          <Thead>
            <Tr>
              <Th color="whiteAlpha.600">Filename</Th>
              <Th color="whiteAlpha.600">Type</Th>
              <Th color="whiteAlpha.600" isNumeric>
                Confidence
              </Th>
              <Th color="whiteAlpha.600">Status</Th>
              <Th color="whiteAlpha.600" isNumeric>Anomalies</Th>
              <Th color="whiteAlpha.600" isNumeric>Time</Th>
              <Th color="whiteAlpha.600">Quality</Th>
              <Th color="whiteAlpha.600">Signals</Th>
            </Tr>
          </Thead>
          <Tbody>
            {documents.map((doc, idx) => (
              <Tr
                key={`${doc.document_id ?? doc.filename}-${idx}`}
                cursor="pointer"
                onClick={() => setSelectedDocId(doc.document_id ?? null)}
                bg={doc.document_id === selectedDocId ? "whiteAlpha.100" : undefined}
              >
                <Td>{doc.filename ?? "-"}</Td>
                <Td>
                  <Badge colorScheme="purple" variant="subtle" fontSize="xs">
                    {doc.doc_type ?? "-"}
                  </Badge>
                </Td>
                <Td isNumeric>
                  {doc.confidence != null ? (
                    <Tooltip label={`${(doc.confidence * 100).toFixed(1)}%`}>
                      <Box display="inline-block">
                        <CircularProgress
                          value={doc.confidence * 100}
                          size="32px"
                          color={doc.confidence >= 0.8 ? "green.400" : doc.confidence >= 0.5 ? "orange.400" : "red.400"}
                          trackColor="whiteAlpha.200"
                        >
                          <CircularProgressLabel fontSize="8px">
                            {Math.round(doc.confidence * 100)}
                          </CircularProgressLabel>
                        </CircularProgress>
                      </Box>
                    </Tooltip>
                  ) : "-"}
                </Td>
                <Td>
                  <Badge
                    colorScheme={
                      doc.status === "processed"
                        ? "green"
                        : doc.status === "failed"
                        ? "red"
                        : "orange"
                    }
                  >
                    {doc.status.toUpperCase()}
                  </Badge>
                </Td>
                <Td isNumeric>
                  {(doc.anomalies_count ?? 0) > 0 ? (
                    <Badge colorScheme="red" variant="subtle">
                      {doc.anomalies_count}
                    </Badge>
                  ) : (
                    <Badge colorScheme="green" variant="subtle">0</Badge>
                  )}
                </Td>
                <Td isNumeric>
                  <Text fontSize="xs" color="whiteAlpha.700">
                    {doc.processing_time_ms ? `${(doc.processing_time_ms / 1000).toFixed(1)}s` : "-"}
                  </Text>
                </Td>
                <Td>
                  <Text fontSize="xs" color="whiteAlpha.700">
                    {typeof doc.quality_metrics?.score === "number"
                      ? `${Math.round(doc.quality_metrics.score * 100)}%`
                      : "-"}
                  </Text>
                </Td>
                <Td>
                  <HStack spacing={1} flexWrap="wrap">
                    {doc.layout?.tables && (
                      <Badge colorScheme="purple" variant="subtle" fontSize="2xs">
                        Tables
                      </Badge>
                    )}
                    {doc.layout?.handwriting && (
                      <Badge colorScheme="orange" variant="subtle" fontSize="2xs">
                        HW
                      </Badge>
                    )}
                    {doc.review_reasons && doc.review_reasons.length > 0 && (
                      <Badge colorScheme="red" variant="subtle" fontSize="2xs">
                        {doc.review_reasons.length} flags
                      </Badge>
                    )}
                    {doc.validation?.warnings && doc.validation.warnings.length > 0 && (
                      <Badge colorScheme="yellow" variant="subtle" fontSize="2xs">
                        {doc.validation.warnings.length} warn
                      </Badge>
                    )}
                    {!doc.layout && !doc.review_reasons?.length && <Text fontSize="xs">-</Text>}
                  </HStack>
                </Td>
              </Tr>
            ))}
            {documents.length === 0 && (
              <Tr>
                <Td colSpan={8}>
                  <Text fontSize="sm" color="whiteAlpha.600">
                    No documents ingested yet.
                  </Text>
                </Td>
              </Tr>
            )}
          </Tbody>
        </Table>
      </Box>

      <Drawer isOpen={isDrawerOpen} placement="bottom" onClose={() => setIsDrawerOpen(false)}>
        <DrawerOverlay />
        <DrawerContent bg="obsidian.900" borderTopRadius="24px" border="1px solid" borderColor="whiteAlpha.100">
          <DrawerCloseButton />
          <DrawerHeader color="whiteAlpha.800">Full backend trace</DrawerHeader>
          <DrawerBody>
            {(() => {
              const selected = documents.find((doc) => doc.document_id === selectedDocId);
              if (!selected) {
                return (
                  <Text fontSize="sm" color="whiteAlpha.600">
                    Select a document to view its backend trace.
                  </Text>
                );
              }
              return (
                <VStack align="stretch" spacing={4}>
                  <Box
                    as="pre"
                    fontSize="xs"
                    color="green.200"
                    whiteSpace="pre-wrap"
                    fontFamily="mono"
                    p={3}
                    borderRadius="16px"
                    bg="blackAlpha.700"
                    border="1px solid"
                    borderColor="whiteAlpha.200"
                    maxH="220px"
                    overflowY="auto"
                  >
                    {(selected.debug_log ?? ["No debug log captured."]).map(
                      (line, idx) => `> ${line}${idx < (selected.debug_log?.length ?? 1) - 1 ? "\n" : ""}`
                    )}
                  </Box>
                  <Box
                    as="pre"
                    fontSize="xs"
                    color="whiteAlpha.800"
                    whiteSpace="pre-wrap"
                    fontFamily="mono"
                    p={3}
                    borderRadius="16px"
                    bg="blackAlpha.600"
                    border="1px solid"
                    borderColor="whiteAlpha.200"
                    maxH="320px"
                    overflowY="auto"
                  >
                    {JSON.stringify(selected, null, 2)}
                  </Box>
                </VStack>
              );
            })()}
          </DrawerBody>
        </DrawerContent>
      </Drawer>
    </VStack>
  );
}

