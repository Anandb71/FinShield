import {
  Box,
  Button,
  Heading,
  Text,
  VStack,
  HStack,
  Table,
  Thead,
  Tr,
  Th,
  Tbody,
  Td,
  Badge,
  useToast,
  Spinner,
  Input
} from "@chakra-ui/react";
import { useRef, useState } from "react";
import { useMutation } from "@tanstack/react-query";

import { api } from "../api/client";
import type { IngestionSummary } from "../api/types";

export default function IngestionPage() {
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const toast = useToast();
  const [documents, setDocuments] = useState<IngestionSummary[]>([]);

  const ingestMutation = useMutation({
    mutationFn: async (files: FileList) => {
      const formData = new FormData();
      Array.from(files).forEach((file) => {
        formData.append("files", file);
      });
      const { data } = await api.post<{ documents: IngestionSummary[] }>(
        "/ingestion/documents",
        formData,
        {
          headers: { "Content-Type": "multipart/form-data" }
        }
      );
      return data.documents;
    },
    onSuccess: (docs) => {
      setDocuments((prev) => [...prev, ...docs]);
      toast({
        title: "Ingestion complete",
        description: `Processed ${docs.length} document(s).`,
        status: "success",
        duration: 3000,
        isClosable: true
      });
    },
    onError: (err: unknown) => {
      console.error(err);
      toast({
        title: "Ingestion failed",
        description: "Unable to upload documents. Check backend logs.",
        status: "error",
        duration: 4000,
        isClosable: true
      });
    }
  });

  const onSelectFiles = () => {
    if (fileInputRef.current) {
      fileInputRef.current.click();
    }
  };

  const onFilesChanged = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return;
    ingestMutation.mutate(e.target.files);
    e.target.value = "";
  };

  return (
    <VStack align="stretch" spacing={6}>
      <Box>
        <Heading size="md">Document Ingestion</Heading>
        <Text fontSize="sm" color="gray.400">
          Upload bank statements, invoices, payslips and more for automated analysis.
        </Text>
      </Box>

      <Box
        borderWidth="1px"
        borderRadius="lg"
        borderStyle="dashed"
        borderColor="gray.600"
        p={8}
        textAlign="center"
      >
        <VStack spacing={4}>
          <Text fontWeight="medium">
            Drop files here or{" "}
            <Button
              variant="link"
              colorScheme="blue"
              onClick={onSelectFiles}
              isDisabled={ingestMutation.isPending}
            >
              browse
            </Button>
          </Text>
          <Text fontSize="xs" color="gray.400">
            Supported: PDF, PNG, JPG, JPEG
          </Text>
          <Input
            ref={fileInputRef}
            type="file"
            multiple
            accept=".pdf,.png,.jpg,.jpeg"
            display="none"
            onChange={onFilesChanged}
          />
          <Button
            colorScheme="blue"
            onClick={onSelectFiles}
            isLoading={ingestMutation.isPending}
          >
            {ingestMutation.isPending ? "Uploading..." : "Upload documents"}
          </Button>
        </VStack>
      </Box>

      <HStack justify="space-between">
        <Heading size="sm">Recent uploads</Heading>
        {ingestMutation.isPending && (
          <HStack spacing={2}>
            <Spinner size="sm" />
            <Text fontSize="xs" color="gray.400">
              Processing...
            </Text>
          </HStack>
        )}
      </HStack>

      <Box borderWidth="1px" borderRadius="lg" overflowX="auto">
        <Table size="sm">
          <Thead>
            <Tr>
              <Th>Filename</Th>
              <Th>Type</Th>
              <Th isNumeric>Confidence</Th>
              <Th>Status</Th>
            </Tr>
          </Thead>
          <Tbody>
            {documents.map((doc, idx) => (
              <Tr key={`${doc.document_id ?? doc.filename}-${idx}`}>
                <Td>{doc.filename ?? "-"}</Td>
                <Td>{doc.doc_type ?? "-"}</Td>
                <Td isNumeric>
                  {doc.confidence != null
                    ? `${Math.round(doc.confidence * 100)}%`
                    : "-"}
                </Td>
                <Td>
                  <Badge
                    colorScheme={
                      doc.status === "success"
                        ? "green"
                        : doc.status === "failed"
                        ? "red"
                        : "yellow"
                    }
                  >
                    {doc.status.toUpperCase()}
                  </Badge>
                </Td>
              </Tr>
            ))}
            {documents.length === 0 && (
              <Tr>
                <Td colSpan={4}>
                  <Text fontSize="sm" color="gray.500">
                    No documents ingested yet.
                  </Text>
                </Td>
              </Tr>
            )}
          </Tbody>
        </Table>
      </Box>
    </VStack>
  );
}

