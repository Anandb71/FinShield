import {
  Box,
  Flex,
  Link,
  Text,
  VStack,
  HStack,
  Icon,
  useColorModeValue
} from "@chakra-ui/react";
import { NavLink, Route, Routes } from "react-router-dom";
import { FiFilePlus, FiList, FiBarChart2 } from "react-icons/fi";

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
  const activeBg = useColorModeValue("gray.100", "gray.700");

  return (
    <NavLink to={to} style={{ width: "100%" }}>
      {({ isActive }) => (
        <HStack
          px={3}
          py={2}
          borderRadius="md"
          spacing={3}
          bg={isActive ? activeBg : "transparent"}
          _hover={{ bg: activeBg }}
        >
          <Icon as={icon} />
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
    <Flex minH="100vh">
      <Box
        as="nav"
        w="260px"
        borderRightWidth="1px"
        borderColor={useColorModeValue("gray.200", "gray.700")}
        py={6}
        px={4}
      >
        <VStack align="stretch" spacing={8}>
          <Box>
            <Text fontSize="lg" fontWeight="bold">
              FinShield
            </Text>
            <Text fontSize="xs" color="gray.400">
              Universal Financial Document Intelligence
            </Text>
          </Box>

          <VStack align="stretch" spacing={2}>
            <SidebarLink to="/ingestion" icon={FiFilePlus} label="Ingestion" />
            <SidebarLink to="/review" icon={FiList} label="Review Queue" />
            <SidebarLink to="/dashboard" icon={FiBarChart2} label="Quality Dashboard" />
          </VStack>

          <Box mt="auto" fontSize="xs" color="gray.500">
            <Text>
              Backend:{" "}
              <Link href="http://127.0.0.1:8000/docs" isExternal color="blue.300">
                /docs
              </Link>
            </Text>
          </Box>
        </VStack>
      </Box>

      <Box flex="1" p={6}>
        <Routes>
          <Route path="/" element={<IngestionPage />} />
          <Route path="/ingestion" element={<IngestionPage />} />
          <Route path="/review" element={<ReviewQueuePage />} />
          <Route path="/review/:docId" element={<DocumentReviewPage />} />
          <Route path="/dashboard" element={<DashboardPage />} />
        </Routes>
      </Box>
    </Flex>
  );
}

