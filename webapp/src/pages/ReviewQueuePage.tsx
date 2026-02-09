import {
  Badge,
  Box,
  Button,
  Heading,
  HStack,
  Input,
  Select,
  Spinner,
  SimpleGrid,
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
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import confetti from "canvas-confetti";
import { useNavigate } from "react-router-dom";
import { useMemo, useState } from "react";
import { FiAlertTriangle, FiCheckCircle, FiEye, FiShield } from "react-icons/fi";

import { api } from "../api/client";
import type { ReviewQueueItem } from "../api/types";

type ReviewQueueResponse = {
  queue: ReviewQueueItem[];
  count: number;
  message: string;
};

export default function ReviewQueuePage() {
  const navigate = useNavigate();
  const toast = useToast();
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [typeFilter, setTypeFilter] = useState("all");

  const { data, isLoading } = useQuery({
    queryKey: ["reviewQueue"],
    queryFn: async () => {
      const { data } = await api.get<ReviewQueueResponse>("/review/queue");
      return data;
    }
  });

  const approveMutation = useMutation({
    mutationFn: async (docId: string) => {
      await api.post(`/review/${docId}/approve`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["reviewQueue"] });
      confetti({ particleCount: 120, spread: 80, origin: { y: 0.7 } });
      toast({ title: "Approved", status: "success", duration: 1500, isClosable: true });
    }
  });

  const rejectMutation = useMutation({
    mutationFn: async (docId: string) => {
      await api.post(`/review/${docId}/reject`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["reviewQueue"] });
      confetti({ particleCount: 80, spread: 60, origin: { y: 0.7 } });
      toast({ title: "Rejected", status: "warning", duration: 1500, isClosable: true });
    }
  });

  const queue = data?.queue ?? [];
  const typeOptions = useMemo(() => {
    const unique = Array.from(new Set(queue.map((item) => item.doc_type))).filter(Boolean);
    return unique.length ? unique : [];
  }, [queue]);

  const filteredQueue = useMemo(() => {
    return queue.filter((item) => {
      const matchesSearch = searchTerm
        ? `${item.filename} ${item.document_id}`.toLowerCase().includes(searchTerm.toLowerCase())
        : true;
      const matchesStatus = statusFilter === "all" ? true : item.status === statusFilter;
      const matchesType = typeFilter === "all" ? true : item.doc_type === typeFilter;
      return matchesSearch && matchesStatus && matchesType;
    });
  }, [queue, searchTerm, statusFilter, typeFilter]);

  const triageCards = filteredQueue.slice(0, 3);

  return (
    <VStack align="stretch" spacing={6}>
      <Box
        p={[4, 6]}
        borderRadius="24px"
        bg="linear-gradient(120deg, rgba(255,107,107,0.16), rgba(15,17,26,0.95))"
        border="1px solid"
        borderColor="whiteAlpha.100"
      >
        <Text fontSize="xs" color="aurora.violet" textTransform="uppercase" letterSpacing="0.2em">
          Review Queue
        </Text>
        <Heading size="lg" mb={2}>
          Human-in-the-Loop Console
        </Heading>
        <Text fontSize="sm" color="whiteAlpha.700" maxW="620px">
          Documents flagged for manual verification, anomaly review, or confidence
          boosting. Prioritize by confidence, status, or file type.
        </Text>
        <SimpleGrid columns={[2, 4]} spacing={3} mt={4}>
          <Stat p={3} borderRadius="16px" bg="whiteAlpha.100">
            <StatLabel>In queue</StatLabel>
            <StatNumber>{queue.length}</StatNumber>
          </Stat>
          <Stat p={3} borderRadius="16px" bg="whiteAlpha.100">
            <StatLabel>
              <HStack spacing={1}><FiEye size={12} /><Text>Need review</Text></HStack>
            </StatLabel>
            <StatNumber color="orange.300">{queue.filter(i => i.status === "review").length}</StatNumber>
          </Stat>
          <Stat p={3} borderRadius="16px" bg="whiteAlpha.100">
            <StatLabel>
              <HStack spacing={1}><FiAlertTriangle size={12} /><Text>With errors</Text></HStack>
            </StatLabel>
            <StatNumber color="red.300">{queue.filter(i => i.validation_errors.length > 0).length}</StatNumber>
          </Stat>
          <Stat p={3} borderRadius="16px" bg="whiteAlpha.100">
            <StatLabel>
              <HStack spacing={1}><FiShield size={12} /><Text>Low confidence</Text></HStack>
            </StatLabel>
            <StatNumber>{queue.filter(i => (i.confidence ?? 0) < 0.7).length}</StatNumber>
            <StatHelpText>&lt; 70%</StatHelpText>
          </Stat>
        </SimpleGrid>
      </Box>

      <HStack spacing={4} flexWrap="wrap">
        <Input
          size="sm"
          placeholder="Search filename or document id"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          maxW="360px"
        />
        <Select
          size="sm"
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          maxW="160px"
        >
          <option value="all">All status</option>
          <option value="review">Review</option>
          <option value="processed">Processed</option>
          <option value="failed">Failed</option>
        </Select>
        <Select
          size="sm"
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          maxW="180px"
        >
          <option value="all">All types</option>
          {typeOptions.map((type) => (
            <option key={type} value={type}>
              {type}
            </option>
          ))}
        </Select>
      </HStack>

      <SimpleGrid columns={[1, null, 3]} spacing={4}>
        {triageCards.map((item) => {
          const issue = item.validation_errors[0] ?? item.validation_warnings[0];
          const issueText = issue && (issue as { message?: string }).message ? (issue as { message?: string }).message : "No issues detected";
          const errorCount = item.validation_errors.length;
          const warnCount = item.validation_warnings.length;
          const totalIssues = errorCount + warnCount;
          const severityColor = errorCount > 2 ? "red" : errorCount > 0 ? "orange" : "green";
          return (
            <Box
              key={`triage-${item.document_id}`}
              p={4}
              borderRadius="20px"
              bg={errorCount > 2 ? "rgba(255,107,107,0.06)" : "whiteAlpha.50"}
              border="1px solid"
              borderColor={errorCount > 2 ? "rgba(255,107,107,0.2)" : "whiteAlpha.100"}
              boxShadow="soft"
              _hover={{ borderColor: "aurora.violet", transform: "translateY(-2px)" }}
              transition="all 0.2s"
            >
              <HStack justify="space-between" mb={2}>
                <Badge colorScheme="purple" variant="subtle">
                  {item.doc_type}
                </Badge>
                <HStack spacing={1}>
                  <Badge colorScheme={item.status === "review" ? "orange" : "green"}>{item.status.toUpperCase()}</Badge>
                  {totalIssues > 0 && (
                    <Badge colorScheme={severityColor} variant="subtle">
                      {totalIssues} issue{totalIssues > 1 ? "s" : ""}
                    </Badge>
                  )}
                </HStack>
              </HStack>
              <Text fontWeight="semibold" fontSize="sm">
                {item.filename}
              </Text>
              <Text fontSize="xs" color="whiteAlpha.500" mb={1}>
                Confidence: {Math.round((item.confidence ?? 0) * 100)}%
              </Text>
              <Text fontSize="xs" color="whiteAlpha.600" mb={3} noOfLines={2}>
                {issueText}
              </Text>
              <HStack spacing={2}>
                <Tooltip label="Approve extraction">
                  <Button size="xs" colorScheme="green" leftIcon={<FiCheckCircle />} onClick={() => approveMutation.mutate(item.document_id)}>
                    Approve
                  </Button>
                </Tooltip>
                <Button size="xs" colorScheme="red" variant="outline" onClick={() => rejectMutation.mutate(item.document_id)}>
                  Reject
                </Button>
                <Button size="xs" colorScheme="purple" variant="ghost" onClick={() => navigate(`/review/${item.document_id}`)}>
                  Inspect
                </Button>
              </HStack>
            </Box>
          );
        })}
        {triageCards.length === 0 && (
          <Box
            p={4}
            borderRadius="20px"
            bg="whiteAlpha.50"
            border="1px solid"
            borderColor="whiteAlpha.100"
          >
            <Text fontSize="sm" color="whiteAlpha.600">
              No review cards available.
            </Text>
          </Box>
        )}
      </SimpleGrid>

      {isLoading ? (
        <HStack spacing={3} color="whiteAlpha.700">
          <Spinner size="sm" />
          <Text fontSize="sm">Loading review items...</Text>
        </HStack>
      ) : (
        <Box
          borderRadius="24px"
          bg="whiteAlpha.50"
          border="1px solid"
          borderColor="whiteAlpha.100"
          overflowX="auto"
          boxShadow="soft"
        >
          <Table size="sm">
            <Thead>
              <Tr>
                <Th color="whiteAlpha.600">Document</Th>
                <Th color="whiteAlpha.600">Type</Th>
                <Th color="whiteAlpha.600" isNumeric>
                  Confidence
                </Th>
                <Th color="whiteAlpha.600">Status</Th>
                <Th color="whiteAlpha.600">Severity</Th>
                <Th color="whiteAlpha.600">Issues</Th>
                <Th color="whiteAlpha.600"></Th>
              </Tr>
            </Thead>
            <Tbody>
              {filteredQueue.map((item) => {
                const errCount = item.validation_errors.length;
                const warnCount = item.validation_warnings.length;
                const severity = errCount > 2 ? "critical" : errCount > 0 ? "warning" : warnCount > 0 ? "info" : "clean";
                const severityColor = severity === "critical" ? "red" : severity === "warning" ? "orange" : severity === "info" ? "yellow" : "green";
                return (
                <Tr key={item.document_id} _hover={{ bg: "whiteAlpha.50" }}>
                  <Td>
                    <Text fontSize="sm" fontWeight="semibold">
                      {item.filename}
                    </Text>
                    <Text fontSize="xs" color="whiteAlpha.600">
                      {item.document_id.slice(0, 8)}...
                    </Text>
                  </Td>
                  <Td>
                    <Badge colorScheme="purple" variant="subtle">
                      {item.doc_type}
                    </Badge>
                  </Td>
                  <Td isNumeric>
                    <Text color={(item.confidence ?? 0) < 0.7 ? "orange.300" : "green.300"}>
                      {Math.round((item.confidence ?? 0) * 100)}%
                    </Text>
                  </Td>
                  <Td>
                    <Badge colorScheme={item.status === "review" ? "orange" : "green"}>
                      {item.status.toUpperCase()}
                    </Badge>
                  </Td>
                  <Td>
                    <Badge colorScheme={severityColor} variant="subtle">
                      {severity.toUpperCase()}
                    </Badge>
                  </Td>
                  <Td>
                    <Text fontSize="xs" color="whiteAlpha.600">
                      {errCount} errors, {warnCount} warnings
                    </Text>
                    <Text fontSize="xs" color="whiteAlpha.500" noOfLines={1}>
                      {(item.validation_errors[0] as { message?: string })?.message ??
                        (item.validation_warnings[0] as { message?: string })?.message ??
                        "No issues detected"}
                    </Text>
                  </Td>
                  <Td textAlign="right">
                    <Button
                      size="sm"
                      colorScheme="purple"
                      onClick={() => navigate(`/review/${item.document_id}`)}
                    >
                      Open inspector
                    </Button>
                  </Td>
                </Tr>
                );
              })}
              {filteredQueue.length === 0 && (
                <Tr>
                  <Td colSpan={7}>
                    <Text fontSize="sm" color="whiteAlpha.600">
                      No documents pending review.
                    </Text>
                  </Td>
                </Tr>
              )}
            </Tbody>
          </Table>
        </Box>
      )}
    </VStack>
  );
}

