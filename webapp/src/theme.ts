import { extendTheme } from "@chakra-ui/react";

const theme = extendTheme({
  config: {
    initialColorMode: "dark",
    useSystemColorMode: false
  },
  colors: {
    obsidian: {
      950: "#0A0A0F",
      900: "#0F111A",
      800: "#151827",
      700: "#1E2236"
    },
    aurora: {
      coral: "#FF6B6B",
      violet: "#9B8CFF",
      mint: "#41EAD4"
    },
    nebula: {
      900: "#0B0F1C",
      800: "#12192C",
      700: "#1A2340",
      600: "#2B3357"
    },
    glow: {
      violet: "rgba(155, 140, 255, 0.45)",
      mint: "rgba(65, 234, 212, 0.35)",
      coral: "rgba(255, 107, 107, 0.35)"
    }
  },
  radii: {
    none: "0",
    sm: "8px",
    md: "12px",
    lg: "16px",
    xl: "20px",
    "2xl": "26px",
    "3xl": "32px"
  },
  shadows: {
    glow: "0 0 0 1px rgba(155,140,255,0.15), 0 18px 45px rgba(3, 5, 12, 0.6)",
    soft: "0 12px 32px rgba(3, 5, 12, 0.35)",
    card: "0 18px 40px rgba(3, 5, 12, 0.55)"
  },
  styles: {
    global: {
      body: {
        bg: "obsidian.950",
        color: "whiteAlpha.900",
        backgroundImage:
          "radial-gradient(circle at 20% 20%, rgba(155,140,255,0.12), transparent 45%), radial-gradient(circle at 80% 0%, rgba(65,234,212,0.08), transparent 40%), radial-gradient(circle at 40% 80%, rgba(255,107,107,0.10), transparent 55%)",
        backgroundAttachment: "fixed"
      },
      "#root": {
        minHeight: "100vh"
      },
      "*::selection": {
        bg: "aurora.violet",
        color: "obsidian.950"
      }
    }
  },
  fonts: {
    heading: "'Inter', system-ui, sans-serif",
    body: "'Inter', system-ui, sans-serif"
  },
  components: {
    Button: {
      baseStyle: {
        borderRadius: "14px",
        fontWeight: "600"
      }
    },
    Badge: {
      baseStyle: {
        borderRadius: "12px",
        textTransform: "uppercase",
        letterSpacing: "0.08em"
      }
    },
    Table: {
      baseStyle: {
        th: {
          textTransform: "uppercase",
          letterSpacing: "0.14em",
          fontSize: "0.65rem"
        }
      }
    }
  }
});

export default theme;
