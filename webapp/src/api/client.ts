import axios from "axios";

// Default backend base URL; can be overridden via VITE_API_BASE_URL
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "/api";

export const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 120000
});

