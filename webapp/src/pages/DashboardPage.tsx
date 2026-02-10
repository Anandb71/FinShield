import {
  Box,
  Badge,
  Button,
  Heading,
  HStack,
  Icon,
  SimpleGrid,
  Spinner,
  Stat,
  StatHelpText,
  StatLabel,
  StatNumber,
  Tag,
  Table,
  Tbody,
  Td,
  Text,
  Th,
  Thead,
  Tr,
  VStack,
  Progress,
  useToast
} from "@chakra-ui/react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Bar,
  BarChart,
  Cell,
  Legend,
  Pie,
  PieChart,
  ResponsiveContainer,
  Sankey,
  Tooltip as RechartsTooltip,
  XAxis,
  YAxis
} from "recharts";
import { FiActivity, FiAlertTriangle, FiBookOpen, FiClock, FiRefreshCw, FiShield, FiTrendingUp, FiZap } from "react-icons/fi";

import { api } from "../api/client";
import type { DashboardMetrics } from "../api/types";

const SEVERITY_COLORS: Record<string, string> = {
  critical: "#FF6B6B",
  warning: "#FFB86C",
  info: "#9B8CFF"
};

const STATUS_COLORS: Record<string, string> = {
  processed: "#41EAD4",
  review: "#FFB86C",
  failed: "#FF6B6B",
  processing: "#9B8CFF",
  queued: "#636e72"
};

export default function DashboardPage() {
  const { data, isLoading } = useQuery({
    queryKey: ["dashboardMetrics"],
    queryFn: async () => {
      const { data } = await api.get<DashboardMetrics>("/dashboard/metrics");
      return data;
    }
  });

  const toast = useToast();
  const queryClient = useQueryClient();

  const batchReanalyzeMutation = useMutation({
    mutationFn: async () => {
      const { data } = await api.post("/batch/reanalyze");
      return data;
    },
    onSuccess: (result) => {
      queryClient.invalidateQueries({ queryKey: ["dashboardMetrics"] });
      queryClient.invalidateQueries({ queryKey: ["reviewQueue"] });
      const changed = result?.summary?.status_changed ?? 0;
      toast({
        title: "Batch Re-analysis Complete",
        description: `${result?.total_documents ?? 0} documents re-analyzed. ${changed} status changes.`,
        status: "success",
        duration: 4000,
        isClosable: true
      });
    },
    onError: () => {
      toast({ title: "Re-analysis failed", status: "error", duration: 3000, isClosable: true });
    }
  });

  // ── Learning System ──────────────────────────────────────────
  const { data: learningStatus } = useQuery({
    queryKey: ["learningStatus"],
    queryFn: async () => {
      const { data } = await api.get("/admin/learning/status");
      return data as {
        total_documents: number;
        total_corrections: number;
        error_rate: number;
        ready_to_sync: boolean;
        clusters: Record<string, { count: number; examples: { original: string; corrected: string; document_id: string }[] }>;
        recent_events: { event_type: string; payload: Record<string, unknown>; created_at: string }[];
      };
    },
    refetchInterval: 30_000,
  });

  const learningSyncMutation = useMutation({
    mutationFn: async () => {
      const { data } = await api.post("/admin/learning/sync");
      return data as { status: string; synced: number; total_corrections: number };
    },
    onSuccess: (result) => {
      queryClient.invalidateQueries({ queryKey: ["learningStatus"] });
      toast({
        title: "Learning Sync Complete",
        description: `${result?.synced ?? 0} patterns pushed to Backboard.`,
        status: "success",
        duration: 4000,
        isClosable: true,
      });
    },
    onError: () => {
      toast({ title: "Learning sync failed", status: "error", duration: 3000, isClosable: true });
    },
  });

  if (isLoading || !data) {
    return (
      <HStack spacing={3} color="whiteAlpha.700">
        <Spinner size="sm" />
        <Text fontSize="sm">Loading metrics...</Text>
      </HStack>
    );
  }

  const {
    overview,
    anomaly_overview,
    accuracy_by_type,
    top_error_fields,
    knowledge_graph,
    quality_distribution,
    status_distribution,
    benford,
    money_flow
  } = data;

  const accuracySeries = Object.entries(accuracy_by_type).map(([type, stats]) => ({
    type,
    accuracy: Math.round(stats.accuracy * 100),
    count: stats.count
  }));

  const qualitySeries = quality_distribution
    ? [
        { name: "Low", value: quality_distribution.low, fill: "#FF6B6B" },
        { name: "Medium", value: quality_distribution.medium, fill: "#FFB86C" },
        { name: "High", value: quality_distribution.high, fill: "#41EAD4" }
      ]
    : [];

  const statusSeries = status_distribution
    ? Object.entries(status_distribution).map(([status, count]) => ({
        name: status.charAt(0).toUpperCase() + status.slice(1),
        value: count,
        fill: STATUS_COLORS[status] ?? "#636e72"
      }))
    : [];

  const severitySeries = anomaly_overview
    ? Object.entries(anomaly_overview.by_severity)
        .filter(([, v]) => v > 0)
        .map(([severity, count]) => ({
          name: severity.charAt(0).toUpperCase() + severity.slice(1),
          value: count,
          fill: SEVERITY_COLORS[severity] ?? "#636e72"
        }))
    : [];

  const anomalyTypeSeries = anomaly_overview
    ? Object.entries(anomaly_overview.by_type)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 8)
        .map(([type, count]) => ({ type: type.replace(/_/g, " "), count }))
    : [];

  const benfordSeries = benford ?? [];
  const moneyFlow = money_flow ?? { nodes: [], links: [] };

  return (
    <Box>
      <Box
        p={[4, 6]}
        borderRadius="24px"
        bg="linear-gradient(120deg, rgba(155,140,255,0.2), rgba(15,17,26,0.9))"
        border="1px solid"
        borderColor="whiteAlpha.100"
        mb={8}
      >
        <HStack justify="space-between" align="flex-start" spacing={6} flexWrap="wrap">
          <Box>
            <Text fontSize="xs" color="aurora.violet" textTransform="uppercase" letterSpacing="0.2em">
              Command Center
            </Text>
            <Heading size="lg" mb={2}>
              System telemetry
            </Heading>
            <Text fontSize="sm" color="whiteAlpha.700" maxW="560px">
              Live extraction quality, forensic anomaly density, processing performance,
              and knowledge graph growth—all fused into a single mission control view.
            </Text>
          </Box>
          <HStack spacing={3}>
            <Tag colorScheme="green" variant="subtle">
              <HStack spacing={2}>
                <Icon as={FiActivity} />
                <Text>Live ingest</Text>
              </HStack>
            </Tag>
            <Tag colorScheme="purple" variant="subtle">
              <HStack spacing={2}>
                <Icon as={FiShield} />
                <Text>Guardrails on</Text>
              </HStack>
            </Tag>
            {anomaly_overview && anomaly_overview.total_anomalies > 0 && (
              <Tag colorScheme="red" variant="subtle">
                <HStack spacing={2}>
                  <Icon as={FiAlertTriangle} />
                  <Text>{anomaly_overview.total_anomalies} anomalies</Text>
                </HStack>
              </Tag>
            )}
          </HStack>
        </HStack>
      </Box>

      <SimpleGrid columns={[1, 2, 5]} spacing={4} mb={6}>
        <Stat
          p={4}
          borderRadius="20px"
          bg="whiteAlpha.50"
          border="1px solid"
          borderColor="whiteAlpha.100"
          boxShadow="soft"
        >
          <StatLabel>Total documents</StatLabel>
          <StatNumber>{overview.total_documents_processed}</StatNumber>
        </Stat>
        <Stat
          p={4}
          borderRadius="20px"
          bg="whiteAlpha.50"
          border="1px solid"
          borderColor="whiteAlpha.100"
          boxShadow="soft"
        >
          <StatLabel>Corrections</StatLabel>
          <StatNumber>{overview.total_corrections}</StatNumber>
          <StatHelpText>{(overview.error_rate * 100).toFixed(1)}% error rate</StatHelpText>
        </Stat>
        <Stat
          p={4}
          borderRadius="20px"
          bg="whiteAlpha.50"
          border="1px solid"
          borderColor="whiteAlpha.100"
          boxShadow="soft"
        >
          <StatLabel>
            <HStack spacing={1}><FiClock size={12} /><Text>Avg processing</Text></HStack>
          </StatLabel>
          <StatNumber>
            {overview.avg_processing_time_ms
              ? `${(overview.avg_processing_time_ms / 1000).toFixed(1)}s`
              : "-"}
          </StatNumber>
          {overview.max_processing_time_ms && (
            <StatHelpText>max {(overview.max_processing_time_ms / 1000).toFixed(1)}s</StatHelpText>
          )}
        </Stat>
        <Stat
          p={4}
          borderRadius="20px"
          bg={anomaly_overview && anomaly_overview.total_anomalies > 0
            ? "rgba(255,107,107,0.08)"
            : "whiteAlpha.50"}
          border="1px solid"
          borderColor={anomaly_overview && anomaly_overview.total_anomalies > 0
            ? "rgba(255,107,107,0.3)"
            : "whiteAlpha.100"}
          boxShadow="soft"
        >
          <StatLabel>
            <HStack spacing={1}><FiAlertTriangle size={12} /><Text>Anomalies</Text></HStack>
          </StatLabel>
          <StatNumber color={anomaly_overview && anomaly_overview.total_anomalies > 0 ? "red.300" : "green.300"}>
            {anomaly_overview?.total_anomalies ?? 0}
          </StatNumber>
          <StatHelpText>{anomaly_overview?.density ?? 0} per doc</StatHelpText>
        </Stat>
        {knowledge_graph && (
          <Stat
            p={4}
            borderRadius="20px"
            bg="whiteAlpha.50"
            border="1px solid"
            borderColor="whiteAlpha.100"
            boxShadow="soft"
          >
            <StatLabel>
              <HStack spacing={1}><FiZap size={12} /><Text>Graph entities</Text></HStack>
            </StatLabel>
            <StatNumber>{knowledge_graph.entities}</StatNumber>
            <StatHelpText>{knowledge_graph.documents} docs linked</StatHelpText>
          </Stat>
        )}
      </SimpleGrid>

      {/* Anomaly Breakdown */}
      {anomaly_overview && anomaly_overview.total_anomalies > 0 && (
        <Box
          p={5}
          borderRadius="24px"
          bg="rgba(255,107,107,0.06)"
          border="1px solid"
          borderColor="rgba(255,107,107,0.2)"
          mb={6}
          boxShadow="soft"
        >
          <HStack justify="space-between" mb={4}>
            <Heading size="sm">
              <HStack spacing={2}>
                <FiAlertTriangle />
                <Text>Forensic anomaly breakdown</Text>
              </HStack>
            </Heading>
            <Badge colorScheme="red" variant="subtle">
              {anomaly_overview.by_severity.critical ?? 0} critical
            </Badge>
          </HStack>
          <SimpleGrid columns={[1, null, 3]} spacing={6}>
            <Box>
              <Text fontSize="xs" color="whiteAlpha.600" mb={2}>By severity</Text>
              <Box height="160px">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={severitySeries}
                      dataKey="value"
                      nameKey="name"
                      innerRadius={35}
                      outerRadius={65}
                      label={(e) => `${e.name}: ${e.value}`}
                      labelLine={false}
                    >
                      {severitySeries.map((entry, idx) => (
                        <Cell key={`sev-${idx}`} fill={entry.fill} />
                      ))}
                    </Pie>
                    <RechartsTooltip />
                  </PieChart>
                </ResponsiveContainer>
              </Box>
            </Box>
            <Box gridColumn={["span 1", null, "span 2"]}>
              <Text fontSize="xs" color="whiteAlpha.600" mb={2}>By type (top 8)</Text>
              <Box height="160px">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={anomalyTypeSeries} margin={{ left: 8, right: 8 }} layout="vertical">
                    <XAxis type="number" tick={{ fill: "#C7C7D1", fontSize: 10 }} />
                    <YAxis dataKey="type" type="category" tick={{ fill: "#C7C7D1", fontSize: 9 }} width={120} />
                    <RechartsTooltip />
                    <Bar dataKey="count" fill="#FF6B6B" radius={[0, 6, 6, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </Box>
            </Box>
          </SimpleGrid>
        </Box>
      )}

      <SimpleGrid columns={[1, null, 2]} spacing={6}>
        <Box
          borderRadius="24px"
          bg="whiteAlpha.50"
          border="1px solid"
          borderColor="whiteAlpha.100"
          p={4}
          boxShadow="soft"
        >
          <Heading size="sm" mb={3}>
            Accuracy by document type
          </Heading>
          <Box height="220px">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={accuracySeries} margin={{ left: 8, right: 8 }}>
                <XAxis dataKey="type" tick={{ fill: "#C7C7D1", fontSize: 10 }} />
                <YAxis tick={{ fill: "#C7C7D1", fontSize: 10 }} />
                <RechartsTooltip />
                <Bar dataKey="accuracy" fill="#9B8CFF" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </Box>
          <Table size="sm">
            <Thead>
              <Tr>
                <Th color="whiteAlpha.600">Type</Th>
                <Th color="whiteAlpha.600" isNumeric>
                  Accuracy
                </Th>
                <Th color="whiteAlpha.600" isNumeric>
                  Count
                </Th>
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

        <Box
          borderRadius="24px"
          bg="whiteAlpha.50"
          border="1px solid"
          borderColor="whiteAlpha.100"
          p={4}
          boxShadow="soft"
        >
          <SimpleGrid columns={2} spacing={4} mb={4}>
            <Box>
              <Heading size="sm" mb={2}>Quality distribution</Heading>
              <Box height="160px">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={qualitySeries}
                      dataKey="value"
                      nameKey="name"
                      innerRadius={30}
                      outerRadius={60}
                      label
                    >
                      {qualitySeries.map((entry, idx) => (
                        <Cell key={`q-${idx}`} fill={entry.fill} />
                      ))}
                    </Pie>
                    <RechartsTooltip />
                  </PieChart>
                </ResponsiveContainer>
              </Box>
            </Box>
            <Box>
              <Heading size="sm" mb={2}>Status</Heading>
              {statusSeries.length > 0 ? (
                <VStack align="stretch" spacing={2}>
                  {statusSeries.map((s) => (
                    <Box key={s.name}>
                      <HStack justify="space-between" fontSize="xs" mb={1}>
                        <HStack spacing={2}>
                          <Box w={2} h={2} borderRadius="full" bg={s.fill} />
                          <Text color="whiteAlpha.700">{s.name}</Text>
                        </HStack>
                        <Text color="whiteAlpha.800" fontWeight="bold">{s.value}</Text>
                      </HStack>
                      <Progress
                        value={overview.total_documents_processed > 0
                          ? (s.value / overview.total_documents_processed) * 100
                          : 0}
                        size="xs"
                        borderRadius="full"
                        sx={{
                          "& > div": { bg: s.fill }
                        }}
                      />
                    </Box>
                  ))}
                </VStack>
              ) : (
                <Text fontSize="sm" color="whiteAlpha.600">No documents yet.</Text>
              )}
            </Box>
          </SimpleGrid>
          <Heading size="sm" mb={3}>
            Top error fields
          </Heading>
          <Table size="sm">
            <Thead>
              <Tr>
                <Th color="whiteAlpha.600">Field</Th>
                <Th color="whiteAlpha.600" isNumeric>
                  Count
                </Th>
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
                    <Text fontSize="sm" color="whiteAlpha.600">
                      No error clusters recorded yet.
                    </Text>
                  </Td>
                </Tr>
              )}
            </Tbody>
          </Table>
        </Box>
      </SimpleGrid>

      <SimpleGrid columns={[1, null, 2]} spacing={6} mt={6}>
        <Box
          borderRadius="24px"
          bg="whiteAlpha.50"
          border="1px solid"
          borderColor="whiteAlpha.100"
          p={4}
          boxShadow="soft"
        >
          <Heading size="sm" mb={2}>
            Fraud DNA (Benford's Law)
          </Heading>
          <Text fontSize="xs" color="whiteAlpha.600" mb={3}>
            Expected distribution vs observed first-digit frequencies across all transactions
          </Text>
          <Box height="220px">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={benfordSeries} margin={{ left: 8, right: 8 }}>
                <XAxis dataKey="digit" tick={{ fill: "#C7C7D1", fontSize: 10 }} />
                <YAxis tick={{ fill: "#C7C7D1", fontSize: 10 }} />
                <RechartsTooltip />
                <Legend />
                <Bar dataKey="expected" fill="#9FA8DA" radius={[4, 4, 0, 0]} />
                <Bar dataKey="observed" fill="#FF6B6B" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </Box>
        </Box>

        <Box
          borderRadius="24px"
          bg="whiteAlpha.50"
          border="1px solid"
          borderColor="whiteAlpha.100"
          p={4}
          boxShadow="soft"
        >
          <Heading size="sm" mb={2}>
            Money Flow River
          </Heading>
          <Text fontSize="xs" color="whiteAlpha.600" mb={3}>
            Sankey diagram of aggregate transaction flow patterns.
          </Text>
          <Box height="240px">
            <ResponsiveContainer width="100%" height="100%">
              <Sankey
                data={moneyFlow}
                nodePadding={18}
                nodeWidth={12}
                link={{ stroke: "#9B8CFF" }}
              >
                <RechartsTooltip />
              </Sankey>
            </ResponsiveContainer>
          </Box>
        </Box>
      </SimpleGrid>

      {/* ── Batch Controls ────────────────────────────────────────── */}
      <SimpleGrid columns={[1, null, 3]} spacing={6} mt={6}>
        <Box
          borderRadius="24px"
          bg="whiteAlpha.50"
          border="1px solid"
          borderColor="whiteAlpha.100"
          p={5}
          boxShadow="soft"
        >
          <HStack mb={3}>
            <Icon as={FiRefreshCw} color="aurora.violet" />
            <Heading size="sm">Batch Re-analysis</Heading>
          </HStack>
          <Text fontSize="xs" color="whiteAlpha.600" mb={4}>
            Re-run forensic validation on all documents using the latest rules.
            Useful after updating detection thresholds or adding new anomaly patterns.
          </Text>
          <Button
            size="sm"
            colorScheme="purple"
            leftIcon={<FiRefreshCw />}
            onClick={() => batchReanalyzeMutation.mutate()}
            isLoading={batchReanalyzeMutation.isPending}
            loadingText="Re-analyzing..."
          >
            Re-analyze All Documents
          </Button>
          {batchReanalyzeMutation.data && (
            <Box mt={3} p={3} bg="whiteAlpha.50" borderRadius="12px" fontSize="xs">
              <Text color="aurora.mint" fontWeight="bold">Last run results:</Text>
              <VStack align="start" spacing={1} mt={1}>
                <Text>Documents: {batchReanalyzeMutation.data.total_documents}</Text>
                <Text>Time: {batchReanalyzeMutation.data.total_time_ms}ms</Text>
                <Text>Errors found: {batchReanalyzeMutation.data.summary?.errors_found ?? 0}</Text>
                <Text>Warnings: {batchReanalyzeMutation.data.summary?.warnings_found ?? 0}</Text>
                <Text color={batchReanalyzeMutation.data.summary?.status_changed > 0 ? "aurora.coral" : "aurora.mint"}>
                  Status changes: {batchReanalyzeMutation.data.summary?.status_changed ?? 0}
                </Text>
              </VStack>
            </Box>
          )}
        </Box>

        <Box
          borderRadius="24px"
          bg="whiteAlpha.50"
          border="1px solid"
          borderColor="whiteAlpha.100"
          p={5}
          boxShadow="soft"
        >
          <HStack mb={3}>
            <Icon as={FiShield} color="aurora.coral" />
            <Heading size="sm">Forensic Rules</Heading>
          </HStack>
          <Text fontSize="xs" color="whiteAlpha.600" mb={3}>
            Current confidence penalty configuration. Update via the API
            endpoint <Tag size="sm" colorScheme="purple">PUT /api/batch/rules</Tag> to
            adjust thresholds and auto-trigger batch re-analysis.
          </Text>
          <Table size="sm">
            <Thead>
              <Tr>
                <Th color="whiteAlpha.600">Rule</Th>
                <Th color="whiteAlpha.600" isNumeric>Value</Th>
              </Tr>
            </Thead>
            <Tbody>
              <Tr><Td fontSize="xs">Error penalty</Td><Td isNumeric fontSize="xs">−15%</Td></Tr>
              <Tr><Td fontSize="xs">Critical warning</Td><Td isNumeric fontSize="xs">−10%</Td></Tr>
              <Tr><Td fontSize="xs">Normal warning</Td><Td isNumeric fontSize="xs">−3%</Td></Tr>
              <Tr><Td fontSize="xs">Info warning</Td><Td isNumeric fontSize="xs">−1%</Td></Tr>
              <Tr><Td fontSize="xs">Confidence floor</Td><Td isNumeric fontSize="xs">10%</Td></Tr>
              <Tr><Td fontSize="xs">Fraud cap</Td><Td isNumeric fontSize="xs">12%</Td></Tr>
            </Tbody>
          </Table>
        </Box>

        {/* ── Learning System ──────────────────────────────────────── */}
        <Box
          borderRadius="24px"
          bg="whiteAlpha.50"
          border="1px solid"
          borderColor="whiteAlpha.100"
          p={5}
          boxShadow="soft"
        >
          <HStack mb={3}>
            <Icon as={FiBookOpen} color="aurora.mint" />
            <Heading size="sm">Self-Learning Status</Heading>
          </HStack>
          <Text fontSize="xs" color="whiteAlpha.600" mb={4}>
            Tracks human corrections, clusters error patterns, and pushes learning
            messages to the AI so it avoids repeating the same mistakes.
          </Text>

          {learningStatus ? (
            <VStack align="stretch" spacing={3}>
              <SimpleGrid columns={2} spacing={3}>
                <Box p={2} bg="whiteAlpha.50" borderRadius="12px" textAlign="center">
                  <Text fontSize="2xl" fontWeight="bold" color="aurora.mint">
                    {learningStatus.total_corrections}
                  </Text>
                  <Text fontSize="xs" color="whiteAlpha.600">corrections</Text>
                </Box>
                <Box p={2} bg="whiteAlpha.50" borderRadius="12px" textAlign="center">
                  <Text
                    fontSize="2xl"
                    fontWeight="bold"
                    color={learningStatus.error_rate > 0.1 ? "red.300" : "aurora.mint"}
                  >
                    {(learningStatus.error_rate * 100).toFixed(1)}%
                  </Text>
                  <Text fontSize="xs" color="whiteAlpha.600">error rate</Text>
                </Box>
              </SimpleGrid>

              {Object.keys(learningStatus.clusters).length > 0 && (
                <Box>
                  <Text fontSize="xs" fontWeight="bold" color="whiteAlpha.700" mb={1}>
                    Error Clusters
                  </Text>
                  {Object.entries(learningStatus.clusters)
                    .sort(([, a], [, b]) => b.count - a.count)
                    .slice(0, 5)
                    .map(([field, info]) => (
                      <HStack key={field} justify="space-between" fontSize="xs" py={0.5}>
                        <Text color="whiteAlpha.800">{field}</Text>
                        <Badge colorScheme={info.count >= 3 ? "red" : "gray"} variant="subtle">
                          {info.count}x
                        </Badge>
                      </HStack>
                    ))}
                </Box>
              )}

              {learningStatus.recent_events.length > 0 && (
                <Box>
                  <Text fontSize="xs" fontWeight="bold" color="whiteAlpha.700" mb={1}>
                    Recent Events
                  </Text>
                  {learningStatus.recent_events.slice(0, 3).map((ev, i) => (
                    <HStack key={i} fontSize="xs" py={0.5}>
                      <Badge
                        colorScheme={ev.event_type === "learning_sync" ? "green" : "orange"}
                        variant="subtle"
                        fontSize="2xs"
                      >
                        {ev.event_type.replace(/_/g, " ")}
                      </Badge>
                      <Text color="whiteAlpha.500">
                        {new Date(ev.created_at).toLocaleString()}
                      </Text>
                    </HStack>
                  ))}
                </Box>
              )}

              <Button
                size="sm"
                colorScheme="teal"
                leftIcon={<FiBookOpen />}
                onClick={() => learningSyncMutation.mutate()}
                isLoading={learningSyncMutation.isPending}
                loadingText="Syncing..."
                isDisabled={!learningStatus.ready_to_sync}
              >
                {learningStatus.ready_to_sync ? "Sync Learning to AI" : "Cooldown active"}
              </Button>
            </VStack>
          ) : (
            <Text fontSize="xs" color="whiteAlpha.500">Loading learning status...</Text>
          )}
        </Box>
      </SimpleGrid>
    </Box>
  );
}

