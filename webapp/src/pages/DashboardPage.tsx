import {
  Box,
  Heading,
  Text,
  SimpleGrid,
  Stat,
  StatLabel,
  StatNumber,
  StatHelpText,
  Table,
  Thead,
  Tr,
  Th,
  Tbody,
  Td,
  Tag,
  Spinner,
  HStack
} from "@chakra-ui/react";
import { useQuery } from "@tanstack/react-query";

import { api } from "../api/client";
import type { DashboardMetrics } from "../api/types";

export default function DashboardPage() {
  const { data, isLoading } = useQuery({
    queryKey: ["dashboardMetrics"],
    queryFn: async () => {
      const { data } = await api.get<DashboardMetrics>("/dashboard/metrics");
      return data;
    }
  });

  if (isLoading || !data) {
    return (
      <HStack spacing={3}>
        <Spinner size="sm" />
        <Text fontSize="sm" color="gray.400">
          Loading metrics...
        </Text>
      </HStack>
    );
  }

  const { overview, accuracy_by_type, top_error_fields, knowledge_graph } = data;

  return (
    <Box>
      <Heading size="md" mb={2}>
        Extraction Quality Dashboard
      </Heading>
      <Text fontSize="sm" color="gray.400" mb={6}>
        Monitor overall system performance, correction patterns, and knowledge graph
        growth.
      </Text>

      <SimpleGrid columns={[1, 2, 4]} spacing={4} mb={6}>
        <Stat>
          <StatLabel>Total documents processed</StatLabel>
          <StatNumber>{overview.total_documents_processed}</StatNumber>
        </Stat>
        <Stat>
          <StatLabel>Total corrections</StatLabel>
          <StatNumber>{overview.total_corrections}</StatNumber>
          <StatHelpText>{(overview.error_rate * 100).toFixed(1)}% error rate</StatHelpText>
        </Stat>
        <Stat>
          <StatLabel>Avg processing time</StatLabel>
          <StatNumber>{overview.avg_processing_time.toFixed(2)}s</StatNumber>
        </Stat>
        {knowledge_graph && (
          <Stat>
            <StatLabel>Knowledge graph docs</StatLabel>
            <StatNumber>{knowledge_graph.total_documents}</StatNumber>
          </Stat>
        )}
      </SimpleGrid>

      <SimpleGrid columns={[1, null, 2]} spacing={6}>
        <Box borderWidth="1px" borderRadius="lg" p={4}>
          <Heading size="sm" mb={3}>
            Accuracy by document type
          </Heading>
          <Table size="sm">
            <Thead>
              <Tr>
                <Th>Type</Th>
                <Th isNumeric>Accuracy</Th>
                <Th isNumeric>Count</Th>
              </Tr>
            </Thead>
            <Tbody>
              {Object.entries(accuracy_by_type).map(([type, stats]) => (
                <Tr key={type}>
                  <Td>{type}</Td>
                  <Td isNumeric>{(stats.accuracy * 100).toFixed(1)}%</Td>
                  <Td isNumeric>{stats.count}</Td>
                </Tr>
              ))}
            </Tbody>
          </Table>
        </Box>

        <Box borderWidth="1px" borderRadius="lg" p={4}>
          <Heading size="sm" mb={3}>
            Top error fields
          </Heading>
          <Table size="sm">
            <Thead>
              <Tr>
                <Th>Field</Th>
                <Th isNumeric>Count</Th>
              </Tr>
            </Thead>
            <Tbody>
              {top_error_fields.map((f) => (
                <Tr key={f.field}>
                  <Td>
                    <Tag colorScheme="red" size="sm">
                      {f.field}
                    </Tag>
                  </Td>
                  <Td isNumeric>{f.count}</Td>
                </Tr>
              ))}
              {top_error_fields.length === 0 && (
                <Tr>
                  <Td colSpan={2}>
                    <Text fontSize="sm" color="gray.500">
                      No error clusters recorded yet.
                    </Text>
                  </Td>
                </Tr>
              )}
            </Tbody>
          </Table>
        </Box>
      </SimpleGrid>
    </Box>
  );
}

