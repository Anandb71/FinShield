import {
  Box,
  Heading,
  Text,
  Table,
  Thead,
  Tr,
  Th,
  Tbody,
  Td,
  Badge,
  Spinner,
  HStack,
  Button
} from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";

import { api } from "../api/client";

type ReviewItem = {
  document_id: string;
  field: string;
  ocr_value: string;
  suggestion?: string;
  confidence: number;
  doc_type: string;
};

type ReviewQueueResponse = {
  queue: ReviewItem[];
  count: number;
  message: string;
};

export default function ReviewQueuePage() {
  const navigate = useNavigate();

  const { data, isLoading } = useQuery({
    queryKey: ["reviewQueue"],
    queryFn: async () => {
      const { data } = await api.get<ReviewQueueResponse>("/review/queue");
      return data;
    }
  });

  const queue = data?.queue ?? [];

  return (
    <Box>
      <Heading size="md" mb={2}>
        Review Queue
      </Heading>
      <Text fontSize="sm" color="gray.400" mb={4}>
        Documents that require manual verification or corrections.
      </Text>

      {isLoading ? (
        <HStack spacing={3}>
          <Spinner size="sm" />
          <Text fontSize="sm" color="gray.400">
            Loading review items...
          </Text>
        </HStack>
      ) : (
        <Box borderWidth="1px" borderRadius="lg" overflowX="auto">
          <Table size="sm">
            <Thead>
              <Tr>
                <Th>Document</Th>
                <Th>Field</Th>
                <Th>OCR Value</Th>
                <Th>Suggestion</Th>
                <Th isNumeric>Confidence</Th>
                <Th>Type</Th>
                <Th></Th>
              </Tr>
            </Thead>
            <Tbody>
              {queue.map((item) => (
                <Tr key={`${item.document_id}-${item.field}`}>
                  <Td>{item.document_id}</Td>
                  <Td>{item.field}</Td>
                  <Td>{item.ocr_value}</Td>
                  <Td>{item.suggestion ?? "-"}</Td>
                  <Td isNumeric>{item.confidence}%</Td>
                  <Td>
                    <Badge>{item.doc_type}</Badge>
                  </Td>
                  <Td textAlign="right">
                    <Button
                      size="xs"
                      colorScheme="blue"
                      onClick={() => navigate(`/review/${item.document_id}`)}
                    >
                      Open
                    </Button>
                  </Td>
                </Tr>
              ))}
              {queue.length === 0 && (
                <Tr>
                  <Td colSpan={7}>
                    <Text fontSize="sm" color="gray.500">
                      No documents pending review. 🎉
                    </Text>
                  </Td>
                </Tr>
              )}
            </Tbody>
          </Table>
        </Box>
      )}
    </Box>
  );
}

