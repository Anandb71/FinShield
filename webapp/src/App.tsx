import {
  Badge,
  Box,
  Flex,
  HStack,
  Icon,
  Link,
  Text,
  VStack
} from "@chakra-ui/react";
import { NavLink, Route, Routes } from "react-router-dom";
import {
  FiActivity,
  FiCommand,
  FiFilePlus,
  FiList,
  FiShield
} from "react-icons/fi";

import IngestionPage from "./pages/IngestionPage";
import ReviewQueuePage from "./pages/ReviewQueuePage";
import DocumentReviewPage from "./pages/DocumentReviewPage";
import DashboardPage from "./pages/DashboardPage";

function SidebarLink({
  to,
  icon,
  label
}: {
  to: string;
  icon: React.ElementType;
  label: string;
}) {
  return (
    <NavLink to={to} style={{ width: "100%" }}>
      {({ isActive }) => (
        <HStack
          px={4}
          py={3}
          borderRadius="16px"
          spacing={3}
          bg={isActive ? "whiteAlpha.100" : "transparent"}
          _hover={{ bg: "whiteAlpha.100" }}
          transition="all 0.2s ease"
        >
          <Icon as={icon} color="aurora.violet" />
          <Text fontSize="sm" fontWeight="medium">
            {label}
          </Text>
        </HStack>
      )}
    </NavLink>
  );
}

export default function App() {
  return (
    <Flex minH="100vh" bg="obsidian.950" position="relative" overflow="hidden">
      <Box
        position="absolute"
        inset={0}
        pointerEvents="none"
        zIndex={0}
      >
        <Box
          position="absolute"
          top="-120px"
          left="-140px"
          w="360px"
          h="360px"
          bg="glow.violet"
          filter="blur(120px)"
          opacity={0.6}
        />
        <Box
          position="absolute"
          bottom="-120px"
          right="-120px"
          w="320px"
          h="320px"
          bg="glow.mint"
          filter="blur(120px)"
          opacity={0.5}
        />
      </Box>
      <Box
        as="nav"
        w="280px"
        borderRightWidth="1px"
        borderColor="whiteAlpha.100"
        py={8}
        px={6}
        bg="rgba(12, 15, 26, 0.75)"
        backdropFilter="blur(24px)"
        zIndex={1}
      >
        <VStack align="stretch" spacing={8} h="full">
          <HStack spacing={3} align="center">
            <Box
              p={2}
              borderRadius="14px"
              bg="whiteAlpha.100"
              boxShadow="glow"
              backdropFilter="blur(12px)"
            >
              <Icon as={FiShield} color="aurora.coral" fontSize="20px" />
            </Box>
            <Box>
              <Text fontSize="lg" fontWeight="bold">
                Aegis
              </Text>
              <Text fontSize="xs" color="whiteAlpha.700">
                Autonomous Financial Immunosystem
              </Text>
            </Box>
          </HStack>

          <VStack align="stretch" spacing={2}>
            <SidebarLink to="/dashboard" icon={FiCommand} label="Command Center" />
            <SidebarLink to="/ingestion" icon={FiFilePlus} label="Ingestion Bay" />
            <SidebarLink to="/review" icon={FiList} label="Review Queue" />
          </VStack>

          <Box
            mt="auto"
            fontSize="xs"
            color="whiteAlpha.700"
            p={4}
            borderRadius="16px"
            bg="whiteAlpha.50"
            border="1px solid"
            borderColor="whiteAlpha.100"
          >
            <HStack spacing={2} mb={2}>
              <FiActivity />
              <Text>Backend online</Text>
              <Badge colorScheme="green" variant="subtle">
                LIVE
              </Badge>
            </HStack>
            <Text>
              API docs:{" "}
              <Link href="http://127.0.0.1:8000/docs" isExternal color="aurora.violet">
                /docs
              </Link>
            </Text>
          </Box>
        </VStack>
      </Box>

      <Box
        flex="1"
        px={[4, 10]}
        py={8}
        bg="transparent"
        position="relative"
        zIndex={1}
      >
        <Box
          borderRadius="32px"
          bg="rgba(12, 15, 26, 0.6)"
          border="1px solid"
          borderColor="whiteAlpha.100"
          px={[4, 8]}
          py={[6, 8]}
          minH="calc(100vh - 64px)"
          backdropFilter="blur(18px)"
          boxShadow="card"
        >
        <Routes>
          <Route path="/" element={<DashboardPage />} />
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/ingestion" element={<IngestionPage />} />
          <Route path="/review" element={<ReviewQueuePage />} />
          <Route path="/review/:docId" element={<DocumentReviewPage />} />
        </Routes>
        </Box>
      </Box>
    </Flex>
  );
}

