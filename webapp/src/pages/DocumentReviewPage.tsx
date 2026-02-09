import {
  Box,
  Button,
  Heading,
  HStack,
  Input,
  SimpleGrid,
  Spinner,
  Text,
  VStack,
  Table,
  Thead,
  Tr,
  Th,
  Tbody,
  Td,
  Badge
} from "@chakra-ui/react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useParams } from "react-router-dom";
import { useState } from "react";

import { api } from "../api/client";
import type { DocumentAnalysis } from "../api/types";

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

  const { data, isLoading } = useQuery({
    queryKey: ["document", docId],
    enabled: !!docId,
    queryFn: async () => {
      const { data } = await api.get<DocumentAnalysis>(`/documents/${docId}`);
      return data;
    }
  });

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
      setCorrection({
        field_name: "",
        original_value: "",
        corrected_value: ""
      });
    }
  });

  if (!docId) {
    return <Text>Missing document id.</Text>;
  }

  if (isLoading || !data) {
    return (
      <HStack spacing={3}>
        <Spinner size="sm" />
        <Text fontSize="sm" color="gray.400">
          Loading document...
        </Text>
      </HStack>
    );
  }

  const { classification, validation, knowledge_graph } = data;

  return (
    <SimpleGrid columns={[1, null, 2]} spacing={6}>
      {/* Document viewer */}
      <Box>
        <Heading size="md" mb={2}>
          Document
        </Heading>
        <Text fontSize="sm" color="gray.400" mb={4}>
          {data.filename} — {classification.type} (
          {Math.round(classification.confidence * 100)}% confidence)
        </Text>

        <Box
          borderWidth="1px"
          borderRadius="lg"
          overflow="hidden"
          minH="480px"
          bg="gray.800"
        >
          <iframe
            title="Document"
            src={`/api/documents/${encodeURIComponent(
              data.document_id
            )}/file`}
            style={{ width: "100%", height: "100%", border: "none" }}
          />
        </Box>
      </Box>

      {/* Structured data & corrections */}
      <VStack align="stretch" spacing={4}>
        <Box>
          <Heading size="md" mb={2}>
            Extracted fields
          </Heading>
          <Table size="sm" variant="simple">
            <Thead>
              <Tr>
                <Th>Field</Th>
                <Th>Value</Th>
              </Tr>
            </Thead>
            <Tbody>
              {Object.entries(data.extracted_fields).map(([key, value]) => (
                <Tr key={key}>
                  <Td>{key}</Td>
                  <Td>{String(value)}</Td>
                </Tr>
              ))}
              {Object.keys(data.extracted_fields).length === 0 && (
                <Tr>
                  <Td colSpan={2}>
                    <Text fontSize="sm" color="gray.500">
                      No structured fields available.
                    </Text>
                  </Td>
                </Tr>
              )}
            </Tbody>
          </Table>
        </Box>

        <Box>
          <Heading size="sm" mb={2}>
            Validation
          </Heading>
          <HStack spacing={3} mb={2}>
            <Badge colorScheme={validation.valid ? "green" : "red"}>
              {validation.valid ? "PASS" : "FAIL"}
            </Badge>
            <Text fontSize="sm" color="gray.400">
              {validation.errors.length} errors, {validation.warnings.length} warnings
            </Text>
          </HStack>
          <VStack align="stretch" spacing={1}>
            {validation.errors.map((err, idx) => (
              <Text key={`e-${idx}`} fontSize="xs" color="red.300">
                • {err}
              </Text>
            ))}
            {validation.warnings.map((w, idx) => (
              <Text key={`w-${idx}`} fontSize="xs" color="yellow.300">
                • {w}
              </Text>
            ))}
          </VStack>
        </Box>

        <Box>
          <Heading size="sm" mb={2}>
            Suggest a correction
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
              colorScheme="blue"
              alignSelf="flex-start"
              isLoading={correctionMutation.isPending}
              onClick={() => correctionMutation.mutate()}
              isDisabled={
                !correction.field_name || !correction.corrected_value
              }
            >
              Submit correction
            </Button>
          </VStack>
        </Box>

        {knowledge_graph && (
          <Box>
            <Heading size="sm" mb={2}>
              Knowledge graph slice
            </Heading>
            <Text fontSize="xs" color="gray.400" mb={2}>
              {knowledge_graph.nodes.length} nodes, {knowledge_graph.edges.length}{" "}
              edges
            </Text>
            <Table size="xs" variant="simple">
              <Thead>
                <Tr>
                  <Th>Type</Th>
                  <Th>Id</Th>
                </Tr>
              </Thead>
              <Tbody>
                {knowledge_graph.nodes.slice(0, 8).map((n) => (
                  <Tr key={n.id}>
                    <Td>{n.type}</Td>
                    <Td>{n.id}</Td>
                  </Tr>
                ))}
              </Tbody>
            </Table>
          </Box>
        )}
      </VStack>
    </SimpleGrid>
  );
}

